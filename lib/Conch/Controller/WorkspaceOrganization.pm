package Conch::Controller::WorkspaceOrganization;

use Mojo::Base 'Mojolicious::Controller', -signatures;

=pod

=head1 NAME

Conch::Controller::WorkspaceOrganization

=head1 METHODS

=head2 list_workspace_organizations

Get a list of organizations for the current workspace.
Requires the 'admin' role on the workspace.

Response uses the WorkspaceOrganizations json schema.

=cut

sub list_workspace_organizations ($c) {
    my $workspace_id = $c->stash('workspace_id');

    # organizations which can access any ancestor of this workspace
    my $rs = $c->db_workspaces
        ->and_workspaces_above($workspace_id)
        ->related_resultset('organization_workspace_roles')
        ->search_related('organization',
            { 'user_organization_roles.role' => 'admin' },
            { join => { user_organization_roles => 'user_account' }, collapse => 1 },
        )
        ->active
        ->columns([
            (map 'organization.'.$_, qw(id name description)),
            (map 'user_organization_roles.'.$_, qw(organization_id user_id)),
            { map +('user_organization_roles.user_account.'.$_ => 'user_account.'.$_), qw(id name email) },
        ])
        ->order_by(['organization.name', 'user_account.name'])
        ->hri;

    my $org_data = [
        map {
            my $org = $_;
            my $role_via = $c->db_workspaces->role_via_for_organization($workspace_id, $org->{id});
            +{
                role => $role_via->role,
                $role_via->workspace_id ne $workspace_id ? ( role_via_workspace_id => $role_via->workspace_id ) : (),
                admins => [ map $_->{user_account}, (delete $org->{user_organization_roles})->@* ],
                $org->%*,
            }
        }
        $rs->all
    ];

    $c->log->debug('Found '.scalar($org_data->@*).' organizations');
    $c->status(200, $org_data);
}

=head2 add_workspace_organization

Adds a organization to the current workspace, or upgrades an existing role entry to access the
workspace.
Requires the 'admin' role on the workspace.

Optionally takes a query parameter C<send_mail> (defaulting to true), to send an email
to all organization members and all workspace admins.

=cut

sub add_workspace_organization ($c) {
    # Note: this method is very similar to Conch::Controller::WorkspaceUser::add_user

    my $params = $c->validate_query_params('NotifyUsers');
    return if not $params;

    my $input = $c->validate_request('WorkspaceAddOrganization');
    return if not $input;

    my $organization = $c->db_organizations->active->find($input->{organization_id});
    return $c->status(404) if not $organization;

    my $workspace_id = $c->stash('workspace_id');

    # check if the organization already has access to this workspace
    if (my $existing_role_via = $c->db_workspaces
            ->role_via_for_organization($workspace_id, $organization->id)) {
        if ((my $role_cmp = $existing_role_via->role_cmp($input->{role})) >= 0) {
            my $str = 'organization "'.$organization->name.'" already has '.$existing_role_via->role
                .' access to workspace '.$workspace_id
                .($existing_role_via->workspace_id ne $workspace_id
                    ? (' via workspace '.$existing_role_via->workspace_id) : '');

            $c->log->debug($str.': nothing to do'), return $c->status(204)
                if $role_cmp == 0;

            return $c->status(409, { error => $str.': cannot downgrade role to '.$input->{role} })
                if $role_cmp > 0;
        }

        my $rs = $organization->search_related('organization_workspace_roles',
            { workspace_id => $workspace_id });
        if ($rs->exists) {
            $rs->update({ role => $input->{role} });
        }
        else {
            $organization->create_related('organization_workspace_roles', {
                workspace_id => $workspace_id,
                role => $input->{role},
            });
        }

        $c->log->info('Upgraded organization '.$organization->id.' in workspace '.$workspace_id.' to '.$input->{role});

        my $workspace_name = $c->stash('workspace_name') // $c->stash('workspace_rs')->get_column('name')->single;
        if ($params->{send_mail} // 1) {
            $c->send_mail(
                template_file => 'workspace_organization_update_members',
                To => $c->construct_address_list($organization->user_accounts->order_by('user_account.name')),
                From => 'noreply@conch.joyent.us',
                Subject => 'Your Conch access has changed',
                organization => $organization->name,
                workspace => $workspace_name,
                role => $input->{role},
            );
            my @workspace_admins = $c->db_workspaces
                ->and_workspaces_above($workspace_id)
                ->admins('with_sysadmins')
                ->search({
                    'user_account.id' => { -not_in => $organization
                        ->related_resultset('user_organization_roles')
                        ->get_column('user_id')
                        ->as_query },
                });
            $c->send_mail(
                template_file => 'workspace_organization_update_admins',
                To => $c->construct_address_list(@workspace_admins),
                From => 'noreply@conch.joyent.us',
                Subject => 'We modified an organization\'s access to your workspace',
                organization => $organization->name,
                workspace => $workspace_name,
                role => $input->{role},
            ) if @workspace_admins;
        }

        return $c->status(204);
    }

    $organization->create_related('organization_workspace_roles', {
        workspace_id => $workspace_id,
        role => $input->{role},
    });
    $c->log->info('Added organization '.$organization->id.' to workspace '.$workspace_id.' with the '.$input->{role}.' role');

    if ($params->{send_mail} // 1) {
        my $workspace_name = $c->stash('workspace_name') // $c->stash('workspace_rs')->get_column('name')->single;
        $c->send_mail(
            template_file => 'workspace_organization_add_members',
            To => $c->construct_address_list($organization->user_accounts->order_by('user_account.name')),
            From => 'noreply@conch.joyent.us',
            Subject => 'Your Conch access has changed',
            organization => $organization->name,
            workspace => $workspace_name,
            role => $input->{role},
        );
        my @workspace_admins = $c->db_workspaces
            ->and_workspaces_above($workspace_id)
            ->admins('with_sysadmins')
            ->search({
                'user_account.id' => { -not_in => $organization
                    ->related_resultset('user_organization_roles')
                    ->get_column('user_id')
                    ->as_query },
            });
        $c->send_mail(
            template_file => 'workspace_organization_add_admins',
            To => $c->construct_address_list(@workspace_admins),
            From => 'noreply@conch.joyent.us',
            Subject => 'We added an organization to your workspace',
            organization => $organization->name,
            workspace => $workspace_name,
            role => $input->{role},
        ) if @workspace_admins;
    }

    $c->status(204);
}

=head2 remove_workspace_organization

Removes the indicated organization from the workspace, as well as all sub-workspaces.
Requires the 'admin' role on the workspace.

Note this may not have the desired effect if the organization is getting access to the
workspace via a parent workspace. When in doubt, check at C<< GET
/workspace/:workspace_id/organization >>.

Optionally takes a query parameter C<send_mail> (defaulting to true), to send an email
to all organization members and to all workspace admins.

=cut

sub remove_workspace_organization ($c) {
    # Note: this method is very similar to Conch::Controller::WorkspaceUser::remove

    my $params = $c->validate_query_params('NotifyUsers');
    return if not $params;

    my $organization = $c->stash('organization_rs')->single;

    my $rs = $c->db_workspaces
        ->and_workspaces_beneath($c->stash('workspace_id'))
        ->search_related('organization_workspace_roles', { organization_id => $organization->id });

    my $num_rows = $rs->count;
    return $c->status(204) if not $num_rows;

    my $workspace_name = $c->stash('workspace_name') // $c->stash('workspace_rs')->get_column('name')->single;

    $c->log->debug('removing organization '.$organization->name.' from workspace '
        .$workspace_name.' and all sub-workspaces ('.$num_rows.'rows in total)');

    my $deleted = $rs->delete;

    if ($deleted > 0 and $params->{send_mail} // 1) {
        $c->send_mail(
            template_file => 'workspace_organization_remove_members',
            To => $c->construct_address_list($organization->user_accounts->order_by('user_account.name')),
            From => 'noreply@conch.joyent.us',
            Subject => 'Your Conch workspaces have been updated',
            organization => $organization->name,
            workspace => $workspace_name,
        );
        my @workspace_admins = $c->db_workspaces
            ->and_workspaces_above($c->stash('workspace_id'))
            ->admins('with_sysadmins')
            ->search({ 'user_account.id' => { -not_in => $organization->user_accounts->get_column('id')->as_query } });
        $c->send_mail(
            template_file => 'workspace_organization_remove_admins',
            To => $c->construct_address_list(@workspace_admins),
            From => 'noreply@conch.joyent.us',
            Subject => 'We removed an organization from your workspace',
            organization => $organization->name,
            workspace => $workspace_name,
        ) if @workspace_admins;
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
