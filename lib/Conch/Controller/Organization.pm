package Conch::Controller::Organization;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Conch::UUID 'is_uuid';

=pod

=head1 NAME

Conch::Controller::Organization

=head1 METHODS

=head2 get_all

Retrieve a list of organization details (including each organization's admins).

If the user is a system admin, all active organizations are retrieved; otherwise, limits the
list to those organizations of which the user is a member.

Response uses the Organizations json schema.

=cut

sub get_all ($c) {
    my $rs = $c->db_organizations
        ->active
        ->search({ 'user_organization_roles.role' => 'admin' })
        ->prefetch({
                user_organization_roles => 'user_account',
                organization_build_roles => 'build',
            })
        ->order_by([ map $_.'.name', qw(organization user_account build) ]);

    if (not $c->is_system_admin) {
        # normal users can only see organizations in which they are a member
        $rs = $rs->search({ 'organization.id' => { -in =>
                $c->db_user_organization_roles->search({ user_id => $c->stash('user_id') })
                    ->get_column('organization_id')->as_query
            } });
    }

    my @data =
        map +{
            admins => [ map +{ $_->%{qw(id name email)} }, (delete $_->{users})->@* ],
            $_->%*,
        },
        map $_->TO_JSON, $rs->all;

    $c->status(200, \@data);
}

=head2 create

Creates an organization.

Requires the user to be a system admin.

=cut

sub create ($c) {
    my $input = $c->validate_request('OrganizationCreate');
    return if not $input;

    return $c->status(409, { error => 'an organization already exists with that name' })
        if $c->db_organizations->active->search({ $input->%{name} })->exists;

    # turn emails into user_ids, and confirm they all exist...
    # [ user_id|email, $value, $user_id ], [ ... ]
    my @admins = map [
        $_->%*,
       ($_->{user_id} && $c->db_user_accounts->search({ id => $_->{user_id} })->exists ? $_->{user_id}
      : $_->{email} ? $c->db_user_accounts->search_by_email($_->{email})->get_column('id')->single
      : undef)
    ], (delete $input->{admins})->@*;

    my @errors = map join(' ', $_->@[0,1]), grep !$_->[2], @admins;
    return $c->status(409, { error => 'unrecognized '.join(', ', @errors) }) if @errors;

    my $organization = $c->db_organizations->create({
        $input->%*,
        user_organization_roles => [ map +{ user_id => $_->[2], role => 'admin' }, @admins ],
    });
    $c->log->info('created organization '.$organization->id.' ('.$organization->name.')');
    $c->status(303, '/organization/'.$organization->id);
}

=head2 find_organization

Chainable action that uses the C<organization_id_or_name> value provided in the stash (usually
via the request URL) to look up an organization, and stashes the query to get to it in
C<organization_rs>.

If C<require_role> is provided in the stash, it is used as the minimum required role for the user to
continue; otherwise the user must have the 'admin' role.

=cut

sub find_organization ($c) {
    my $identifier = $c->stash('organization_id_or_name');
    my $rs = $c->db_organizations;
    if (is_uuid($identifier)) {
        $c->stash('organization_id', $identifier);
        $rs = $rs->search({ 'organization.id' => $identifier });
    }
    else {
        $c->stash('organization_name', $identifier);
        $rs = $rs->search({ 'organization.name' => $identifier });
    }

    if (not $rs->exists) {
        $c->log->debug('Could not find organization '.$identifier);
        return $c->status(404);
    }

    $rs = $rs->active;
    return $c->status(410) if not $rs->exists;

    my $requires_role = $c->stash('require_role') // 'admin';
    if (not $c->is_system_admin
            and not $rs->search_related('user_organization_roles',
                { user_id => $c->stash('user_id'), role => $requires_role })->exists) {
        $c->log->debug('User lacks the required role ('.$requires_role.') for organization '.$identifier);
        return $c->status(403);
    }

    $c->stash('organization_rs', $rs);
    return 1;
}

=head2 get

Get the details of a single organization, including its members.
Requires the 'admin' role on the organization.

Response uses the Organization json schema.

=cut

sub get ($c) {
    my $rs = $c->stash('organization_rs')
        ->prefetch({
                user_organization_roles => 'user_account',
                organization_build_roles => 'build',
            })
        ->order_by([ map $_.'.name', qw(user_account build) ]);

    return $c->status(200, ($rs->all)[0]);
}

=head2 update

Modifies an organization attribute: one or more of name, description.
Requires the 'admin' role on the organization.

=cut

sub update ($c) {
    my $input = $c->validate_request('OrganizationUpdate');
    return if not $input;

    my $organization = $c->stash('organization_rs')->single;

    return $c->status(409, { error => 'duplicate organization found' })
        if exists $input->{name} and $input->{name} ne $organization->name
            and $c->db_organizations->active->search({ name => $input->{name} })->exists;

    $organization->update($input);
    $c->status(303, '/organization/'.$organization->id);
}

=head2 delete

Deactivates the organization, preventing its members from exercising any privileges from it.

User must have system admin privileges.

=cut

sub delete ($c) {
    my $user_count = 0+$c->stash('organization_rs')
        ->related_resultset('user_organization_roles')
        ->delete;

    my $build_count = 0+$c->stash('organization_rs')
        ->related_resultset('organization_build_roles')
        ->delete;

    $c->stash('organization_rs')->deactivate;

    $c->log->debug('Deactivated organization '.$c->stash('organization_id_or_name')
        .', removing '.$user_count.' user memberships'
        .' and removing from '.$build_count.' builds');
    return $c->status(204);
}

=head2 add_user

Adds a user to the current organization, or upgrades an existing role entry to access the
organization.
Requires the 'admin' role on the organization.

Optionally takes a query parameter C<send_mail> (defaulting to true), to send an email
to the user and to all organization admins.

=cut

sub add_user ($c) {
    my $params = $c->validate_query_params('NotifyUsers');
    return if not $params;

    my $input = $c->validate_request('OrganizationAddUser');
    return if not $input;

    my $user = $c->stash('target_user');
    my $organization_name = $c->stash('organization_name') // $c->stash('organization_rs')->get_column('name')->single;

    # check if the user already has access to this organization
    if (my $existing_role = $c->stash('organization_rs')
            ->search_related('user_organization_roles', { user_id => $user->id })->single) {
        if ($existing_role->role eq $input->{role}) {
            $c->log->debug('user '.$user->id.' ('.$user->name.') already has '.$input->{role}
                .' access to organization '.$c->stash('organization_id_or_name').': nothing to do');
            return $c->status(204);
        }

        $existing_role->update({ role => $input->{role} });
        $c->log->info('Updated access for user '.$user->id.' ('.$user->name.') in organization '
            .$c->stash('organization_id_or_name').' to the '.$input->{role}.' role');

        if ($params->{send_mail} // 1) {
            $c->send_mail(
                template_file => 'organization_user_update_user',
                From => 'noreply',
                Subject => 'Your Conch access has changed',
                organization => $organization_name,
                role => $input->{role},
            );
            my @admins = $c->stash('organization_rs')
                ->admins('with_sysadmins')
                ->search({ 'user_account.id' => { '!=' => $user->id } });
            $c->send_mail(
                template_file => 'organization_user_update_admins',
                To => $c->construct_address_list(@admins),
                From => 'noreply',
                Subject => 'We modified a user\'s access to your organization',
                organization => $organization_name,
                role => $input->{role},
            ) if @admins;
        }

        return $c->status(204);
    }

    $user->create_related('user_organization_roles', {
        organization_id => $c->stash('organization_id') // $c->stash('organization_rs')->get_column('id')->as_query,
        role => $input->{role},
    });
    $c->log->info('Added user '.$user->id.' ('.$user->name.') to organization '.$c->stash('organization_id_or_name').' with the '.$input->{role}.' role');

    if ($params->{send_mail} // 1) {
        $c->send_mail(
            template_file => 'organization_user_add_user',
            From => 'noreply',
            Subject => 'Your Conch access has changed',
            organization => $organization_name,
            role => $input->{role},
        );
        my @admins = $c->stash('organization_rs')
            ->admins('with_sysadmins')
            ->search({ 'user_account.id' => { '!=' => $user->id } });
        $c->send_mail(
            template_file => 'organization_user_add_admins',
            To => $c->construct_address_list(@admins),
            From => 'noreply',
            Subject => 'We added a user to your organization',
            organization => $organization_name,
            role => $input->{role},
        ) if @admins;
    }

    $c->status(204);
}

=head2 remove_user

Removes the indicated user from the organization.
Requires the 'admin' role on the organization.

Optionally takes a query parameter C<send_mail> (defaulting to true), to send an email
to the user and to all organization admins.

=cut

sub remove_user ($c) {
    my $params = $c->validate_query_params('NotifyUsers');
    return if not $params;

    my $user = $c->stash('target_user');
    my $rs = $c->stash('organization_rs')
        ->search_related('user_organization_roles', { user_id => $user->id });
    return $c->status(204) if not $rs->exists;

    return $c->status(409, { error => 'organizations must have an admin' })
        if $rs->search({ role => 'admin' })->exists
            and $c->stash('organization_rs')
                ->search_related('user_organization_roles', { role => 'admin' })->count == 1;

    $c->log->info('removing user '.$user->id.' ('.$user->name.') from organization '.$c->stash('organization_id_or_name'));
    my $deleted = $rs->delete;

    if ($deleted > 0 and $params->{send_mail} // 1) {
        my $organization_name = $c->stash('organization_name') // $c->stash('organization_rs')->get_column('name')->single;
        $c->send_mail(
            template_file => 'organization_user_remove_user',
            From => 'noreply',
            Subject => 'Your Conch organizations have been updated',
            organization => $organization_name,
        );
        my @admins = $c->stash('organization_rs')->admins('with_sysadmins');
        $c->send_mail(
            template_file => 'organization_user_remove_admins',
            To => $c->construct_address_list(@admins),
            From => 'noreply',
            Subject => 'We removed a user from your organization',
            organization => $organization_name,
        ) if @admins;
    }

    return $c->status(204);
}

1;
__END__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<https://www.mozilla.org/en-US/MPL/2.0/>.

=cut
# vim: set ts=4 sts=4 sw=4 et :
