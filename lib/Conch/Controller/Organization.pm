package Conch::Controller::Organization;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Conch::UUID 'is_uuid';

=pod

=head1 NAME

Conch::Controller::Organization

=head1 METHODS

=head2 list

If the user is a system admin, retrieve a list of all active organizations in the database;
otherwise, limits the list to those organizations of which the user is a member.

Note: the only workspaces and roles listed are those reachable via the organization, even if
the user might have direct access to the workspace at a greater role. For comprehensive
information about what workspaces the user can access, and at what role, please use C<GET
/workspace> or C<GET /user/me>.

Response uses the Organizations json schema.

=cut

sub list ($c) {
    my $rs = $c->db_organizations
        ->active
        ->search({ 'user_organization_roles.role' => 'admin' })
        ->prefetch({
                user_organization_roles => 'user_account',
                organization_workspace_roles => 'workspace',
            })
        ->order_by([qw(organization.name user_account.name)]);

    return $c->status(200, [ $rs->all ]) if $c->is_system_admin;

    # normal users can only see organizations in which they are a member
    $rs = $rs->search({ 'organization.id' => { -in =>
                $c->db_user_organization_roles->search({ user_id => $c->stash('user_id') })
                ->get_column('organization_id')->as_query
            } });

    my @data = map $_->TO_JSON, $rs->all;
    my %workspace_ids;
    @workspace_ids{map $_->{id}, $_->{workspaces}->@*} = () foreach @data;

    foreach my $org (@data) {
        foreach my $ws ($org->{workspaces}->@*) {
            undef $ws->{parent_workspace_id}
                if $ws->{parent_workspace_id}
                    and not exists $workspace_ids{$ws->{parent_workspace_id}}
                    and not $c->db_workspaces
                        ->and_workspaces_above($ws->{parent_workspace_id})
                        ->related_resultset('user_workspace_roles')
                        ->exists;
        }
    }

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

Chainable action that validates the C<organization_id> or C<organization_name> provided in the
path, and stashes the query to get to it in C<organization_rs>.

Requires the 'admin' role on the organization (or the user to be a system admin).

=cut

sub find_organization ($c) {
    my $identifier = $c->stash('organization_id_or_name');
    my $rs = $c->db_organizations->active;
    if (is_uuid($identifier)) {
        $c->stash('organization_id', $identifier);
        $rs = $rs->search({ 'organization.id' => $identifier });
    }
    else {
        $c->stash('organization_name', $identifier);
        $rs = $rs->search({ 'organization.name' => $identifier });
    }

    return $c->status(404) if not $rs->exists;

    my $requires_role = $c->stash('require_role') // 'admin';
    if (not $c->is_system_admin
            and not $rs->search_related('user_organization_roles',
                { user_id => $c->stash('user_id'), role => $requires_role })->exists) {
        $c->log->debug('User lacks the required role ('.$requires_role.') for organization '.$identifier);
        return $c->status(403);
    }

    $c->stash('organization_rs', $rs);
}

=head2 get

Get the details of a single organization.
Requires the 'admin' role on the organization.

Note: the only workspaces and roles listed are those reachable via the organization, even if
the user might have direct access to the workspace at a greater role. For comprehensive
information about what workspaces the user can access, and at what role, please use
C<GET /workspace> or C<GET /user/me>.

Response uses the Organization json schema.

=cut

sub get ($c) {
    my $rs = $c->stash('organization_rs')
        ->search({ 'user_organization_roles.role' => 'admin' })
        ->prefetch({
                user_organization_roles => 'user_account',
                organization_workspace_roles => 'workspace',
            })
        ->order_by('user_account.name');

    return $c->status(200, ($rs->all)[0]) if $c->is_system_admin;

    my $org_data = ($rs->all)[0]->TO_JSON;
    my %workspace_ids; @workspace_ids{map $_->{id}, $org_data->{workspaces}->@*} = ();
    foreach my $ws ($org_data->{workspaces}->@*) {
        undef $ws->{parent_workspace_id}
            if $ws->{parent_workspace_id}
                and not exists $workspace_ids{$ws->{parent_workspace_id}}
                and not $c->db_workspaces
                    ->and_workspaces_above($ws->{parent_workspace_id})
                    ->related_resultset('user_workspace_roles')
                    ->exists;
    }

    return $c->status(200, $org_data);
}

=head2 delete

Deactivates the organization, preventing its members from exercising any privileges from it.

User must have system admin privileges.

=cut

sub delete ($c) {
    my $user_count = 0+$c->stash('organization_rs')
        ->related_resultset('user_organization_roles')
        ->delete;

    my $direct_workspaces_rs = $c->stash('organization_rs')
        ->related_resultset('organization_workspace_roles')
        ->get_column('workspace_id');
    my $workspace_count = $c->db_workspaces
        ->and_workspaces_beneath($direct_workspaces_rs->as_query)
        ->count;

    my $build_count = 0+$c->stash('organization_rs')
        ->related_resultset('organization_build_roles')
        ->delete;

    $c->stash('organization_rs')->related_resultset('organization_workspace_roles')->delete;
    $c->stash('organization_rs')->deactivate;

    $c->log->debug('Deactivated organization '.$c->stash('organization_id_or_name')
        .', removing '.$user_count.' user memberships'
        .' and removing from '.$workspace_count.' workspaces'
        .' and '.$build_count.' builds');
    return $c->status(204);
}

=head2 list_users

Get a list of members of the current organization.
Requires the 'admin' role on the organization.

Response uses the OrganizationUsers json schema.

=cut

sub list_users ($c) {
    my $rs = $c->stash('organization_rs')
        ->related_resultset('user_organization_roles')
        ->related_resultset('user_account')
        ->active
        ->columns([ { role => 'user_organization_roles.role' }, map 'user_account.'.$_, qw(id name email) ])
        ->order_by([ { -desc => 'role' }, 'name' ]);

    $c->status(200, [ $rs->hri->all ]);
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

    my $user_rs = $c->db_user_accounts->active;
    my $user = $input->{user_id} ? $user_rs->find($input->{user_id})
        : $input->{email} ? $user_rs->find_by_email($input->{email})
        : undef;
    return $c->status(404) if not $user;

    $c->stash('target_user', $user);
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
                From => 'noreply@conch.joyent.us',
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
                From => 'noreply@conch.joyent.us',
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
            From => 'noreply@conch.joyent.us',
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
            From => 'noreply@conch.joyent.us',
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
            From => 'noreply@conch.joyent.us',
            Subject => 'Your Conch organizations have been updated',
            organization => $organization_name,
        );
        my @admins = $c->stash('organization_rs')->admins('with_sysadmins');
        $c->send_mail(
            template_file => 'organization_user_remove_admins',
            To => $c->construct_address_list(@admins),
            From => 'noreply@conch.joyent.us',
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
one at L<http://mozilla.org/MPL/2.0/>.

=cut
# vim: set ts=4 sts=4 sw=4 et :
