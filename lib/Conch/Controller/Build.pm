package Conch::Controller::Build;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Conch::UUID 'is_uuid';

=pod

=head1 NAME

Conch::Controller::Build

=head1 METHODS

=head2 list

If the user is a system admin, retrieve a list of all builds in the database; otherwise,
limits the list to those build of which the user is a member.

Response uses the Builds json schema.

=cut

sub list ($c) {
    my $rs = $c->db_builds
        ->search({ 'user_build_roles.role' => 'admin' })
        ->prefetch([ { user_build_roles => 'user_account' }, 'completed_user' ])
        ->order_by([qw(build.name user_account.name)]);

    return $c->status(200, [ $rs->all ]) if $c->is_system_admin;

    # normal users can only see builds in which they are a member
    $rs = $rs->search({ 'build.id' => { -in =>
                $c->db_builds->with_user_role($c->stash('user_id'), 'ro')->get_column('id')->as_query
            } })
        if not $c->is_system_admin;

    $c->status(200, [ $rs->all ]);
}

=head2 create

Creates a build.

Requires the user to be a system admin.

=cut

sub create ($c) {
    my $input = $c->validate_request('BuildCreate');
    return if not $input;

    return $c->status(409, { error => 'a build already exists with that name' })
        if $c->db_builds->search({ $input->%{name} })->exists;

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

    my $build = $c->db_builds->create({
        $input->%*,
        user_build_roles => [ map +{ user_id => $_->[2], role => 'admin' }, @admins ],
    });
    $c->log->info('created build '.$build->id.' ('.$build->name.')');
    $c->status(303, '/build/'.$build->id);
}

=head2 find_build

Chainable action that validates the C<build_id> or C<build_name> provided in the
path, and stashes the query to get to it in C<build_rs>.

If C<require_role> is provided, it is used as the minimum required role for the user to
continue; otherwise the user must be a system admin.

=cut

sub find_build ($c) {
    my $identifier = $c->stash('build_id_or_name');
    my $rs = $c->db_builds;
    if (is_uuid($identifier)) {
        $c->stash('build_id', $identifier);
        $rs = $rs->search({ 'build.id' => $identifier });
    }
    else {
        $c->stash('build_name', $identifier);
        $rs = $rs->search({ 'build.name' => $identifier });
    }

    return $c->status(404) if not $rs->exists;

    CHECK_ACCESS: {
        if ($c->is_system_admin) {
            $c->log->debug('User has system admin access to build '.$identifier);
            last CHECK_ACCESS;
        }

        my $requires_role = $c->stash('require_role') // 'admin';
        if ($rs->user_has_role($c->stash('user_id'), $requires_role)) {
            $c->log->debug('User has '.$requires_role.' access to build '.$identifier.' via role entry');
            last CHECK_ACCESS;
        }

        $c->log->debug('User lacks the required role ('.$requires_role.') for build '.$identifier);
        return $c->status(403);
    }

    $c->stash('build_rs', $rs);
}

=head2 get

Get the details of a single build.
Requires the 'read-only' role on the build.

Response uses the Build json schema.

=cut

sub get ($c) {
    my ($build) = $c->stash('build_rs')
        ->search({ 'user_build_roles.role' => 'admin' })
        ->prefetch([ { user_build_roles => 'user_account' }, 'completed_user' ])
        ->order_by('user_account.name')
        ->all;
    $c->status(200, $build);
}

=head2 update

Modifies a build attribute: one or more of description, started, completed.
Requires the 'admin' role on the build.

=cut

sub update ($c) {
    my $input = $c->validate_request('BuildUpdate');
    return if not $input;

    my $build = $c->stash('build_rs')->single;
    my %old_columns = $build->get_columns;

    # set locally but do not save to db just yet
    $build->set_columns($input);

    return $c->status(409, { error => 'build cannot be completed before it is started' })
        if $build->completed and (not $build->started or $build->started > $build->completed);

    return $c->status(409, { error => 'build was already completed' })
        if $build->completed and $old_columns{completed};

    $c->log->info('build '.$build->id.' ('.$build->name.') started')
        if $build->started and not $old_columns{started};

    if (not $build->completed and $build->completed_user_id) {
        $build->completed_user_id(undef);
        $c->log->info('build '.$build->id.' ('.$build->name
            .') moved out of completed state');
    }
    elsif ($build->completed and not $build->completed_user_id) {
        $build->completed_user_id($c->stash('user')->id);
        my $users_updated = $build->search_related('user_build_roles', { role => 'rw' })
            ->update({ role => 'ro' });
        $c->log->info('build '.$build->id.' ('.$build->name
            .') completed; '.(0+$users_updated).' users had role converted from rw to ro');
    }

    $build->update if $build->is_changed;

    $c->status(303, '/build/'.$build->id);
}

=head2 list_users

Get a list of user members of the current build.
Requires the 'admin' role on the build.

Response uses the BuildUsers json schema.

=cut

sub list_users ($c) {
    my $rs = $c->stash('build_rs')
        ->related_resultset('user_build_roles')
        ->related_resultset('user_account')
        ->active
        ->columns([ { role => 'user_build_roles.role' }, map 'user_account.'.$_, qw(id name email) ])
        ->order_by([ { -desc => 'role' }, 'name' ]);

    $c->status(200, [ $rs->hri->all ]);
}

=head2 add_user

Adds a user to the current build, or upgrades an existing role entry to access the build.
Requires the 'admin' role on the build.

Optionally takes a query parameter C<send_mail> (defaulting to true), to send an email
to the user and to all build admins.

This endpoint is nearly identical to L<Conch::Controller::Organization/add_user>.

=cut

sub add_user ($c) {
    my $params = $c->validate_query_params('NotifyUsers');
    return if not $params;

    my $input = $c->validate_request('BuildAddUser');
    return if not $input;

    my $user_rs = $c->db_user_accounts->active;
    my $user = $input->{user_id} ? $user_rs->find($input->{user_id})
        : $input->{email} ? $user_rs->find_by_email($input->{email})
        : undef;
    return $c->status(404) if not $user;

    $c->stash('target_user', $user);
    my $build_name = $c->stash('build_name') // $c->stash('build_rs')->get_column('name')->single;

    # check if the user already has access to this build
    if (my $existing_role = $c->stash('build_rs')
            ->search_related('user_build_roles', { user_id => $user->id })->single) {
        if ($existing_role->role eq $input->{role}) {
            $c->log->debug('user '.$user->id.' ('.$user->name.') already has '.$input->{role}
                .' access to build '.$c->stash('build_id_or_name').': nothing to do');
            return $c->status(204);
        }

        $existing_role->update({ role => $input->{role} });
        $c->log->info('Updated access for user '.$user->id.' ('.$user->name.') in build '
            .$c->stash('build_id_or_name').' to the '.$input->{role}.' role');

        if ($params->{send_mail} // 1) {
            $c->send_mail(
                template_file => 'build_user_update_user',
                From => 'noreply@conch.joyent.us',
                Subject => 'Your Conch access has changed',
                build => $build_name,
                role => $input->{role},
            );
            my @admins = $c->stash('build_rs')
                ->admins('with_sysadmins')
                ->search({ 'user_account.id' => { '!=' => $user->id } });
            $c->send_mail(
                template_file => 'build_user_update_admins',
                To => $c->construct_address_list(@admins),
                From => 'noreply@conch.joyent.us',
                Subject => 'We modified a user\'s access to your build',
                build => $build_name,
                role => $input->{role},
            ) if @admins;
        }

        return $c->status(204);
    }

    $user->create_related('user_build_roles', {
        build_id => $c->stash('build_id') // $c->stash('build_rs')->get_column('id')->single,
        role => $input->{role},
    });
    $c->log->info('Added user '.$user->id.' ('.$user->name.') to build '.$c->stash('build_id_or_name').' with the '.$input->{role}.' role');

    if ($params->{send_mail} // 1) {
        $c->send_mail(
            template_file => 'build_user_add_user',
            From => 'noreply@conch.joyent.us',
            Subject => 'Your Conch access has changed',
            build => $build_name,
            role => $input->{role},
        );
        my @admins = $c->stash('build_rs')
            ->admins('with_sysadmins')
            ->search({ 'user_account.id' => { '!=' => $user->id } });
        $c->send_mail(
            template_file => 'build_user_add_admins',
            To => $c->construct_address_list(@admins),
            From => 'noreply@conch.joyent.us',
            Subject => 'We added a user to your build',
            build => $build_name,
            role => $input->{role},
        ) if @admins;
    }

    $c->status(204);
}

=head2 remove_user

Removes the indicated user from the build.
Requires the 'admin' role on the build.

Optionally takes a query parameter C<send_mail> (defaulting to true), to send an email
to the user and to all build admins.

This endpoint is nearly identical to L<Conch::Controller::Organization/remove_user>.

=cut

sub remove_user ($c) {
    my $params = $c->validate_query_params('NotifyUsers');
    return if not $params;

    my $user = $c->stash('target_user');
    my $rs = $c->stash('build_rs')
        ->search_related('user_build_roles', { user_id => $user->id });
    return $c->status(204) if not $rs->exists;

    return $c->status(409, { error => 'builds must have an admin' })
        if $rs->search({ role => 'admin' })->exists
            and $c->stash('build_rs')
                ->search_related('user_build_roles', { role => 'admin' })->count == 1;

    $c->log->info('removing user '.$user->id.' ('.$user->name.') from build '.$c->stash('build_id_or_name'));
    my $deleted = $rs->delete;

    if ($deleted > 0 and $params->{send_mail} // 1) {
        my $build_name = $c->stash('build_name') // $c->stash('build_rs')->get_column('name')->single;
        $c->send_mail(
            template_file => 'build_user_remove_user',
            From => 'noreply@conch.joyent.us',
            Subject => 'Your Conch builds have been updated',
            build => $build_name,
        );
        my @admins = $c->stash('build_rs')->admins('with_sysadmins');
        $c->send_mail(
            template_file => 'build_user_remove_admins',
            To => $c->construct_address_list(@admins),
            From => 'noreply@conch.joyent.us',
            Subject => 'We removed a user from your build',
            build => $build_name,
        ) if @admins;
    }

    return $c->status(204);
}

=head2 list_organizations

Get a list of organization members of the current build.
Requires the 'admin' role on the build.

Response uses the BuildOrganizations json schema.

=cut

sub list_organizations ($c) {
    my $rs = $c->db_organizations
        ->search(
            {
                build_id => $c->stash('build_id'),
                'user_organization_roles.role' => 'admin',
            },
            {
                join => [ 'organization_build_roles', { user_organization_roles => 'user_account' } ],
                collapse => 1,
            },
        )
        ->active
        ->columns([
            (map 'organization.'.$_, qw(id name description)),
            (map +('organization_build_roles.'.$_), qw(organization_id build_id role)),
            (map +('user_organization_roles.'.$_), qw(user_id organization_id)),
            +{ map +('user_organization_roles.user_account.'.$_ => 'user_account.'.$_), qw(id name email) },
        ])
        ->order_by([qw(organization.name user_account.name)])
        ->hri;

    my $org_data = [
        map {
            my $org = $_;
            +{
                role => (delete $_->{organization_build_roles})->[0]{role},
                admins => [ map $_->{user_account}, (delete $org->{user_organization_roles})->@* ],
                $org->%*,
            }
        }
        $rs->all
    ];

    $c->log->debug('Found '.scalar($org_data->@*).' organizations');
    $c->status(200, $org_data);
}

=head2 add_organization

Adds a organization to the current build, or upgrades an existing role entry to access the
build.
Requires the 'admin' role on the build.

Optionally takes a query parameter C<send_mail> (defaulting to true), to send an email
to all organization members and all build admins.

=cut

sub add_organization ($c) {
    # Note: this method is very similar to Conch::Controller::WorkspaceUser::add_user
    # and Conch::Controller::WorkspaceOrganization::add_workspace_organization

    my $params = $c->validate_query_params('NotifyUsers');
    return if not $params;

    my $input = $c->validate_request('BuildAddOrganization');
    return if not $input;

    my $organization = $c->db_organizations->active->find($input->{organization_id});
    return $c->status(404) if not $organization;

    my $build_id = $c->stash('build_id');

    # check if the organization already has access to this build
    if (my $existing_role = $c->stash('build_rs')
            ->search_related('organization_build_roles', { organization_id => $organization->id })
            ->single) {
        if ((my $role_cmp = $existing_role->role_cmp($input->{role})) >= 0) {
            my $str = 'organization "'.$organization->name.'" already has '.$existing_role->role
                .' access to build '.$build_id;

            $c->log->debug($str.': nothing to do'), return $c->status(204)
                if $role_cmp == 0;

            return $c->status(409, { error => $str.': cannot downgrade role to '.$input->{role} })
                if $role_cmp > 0;
        }

        $existing_role->update({ role => $input->{role} });
        $c->log->info('Upgraded organization '.$organization->id.' in build '.$build_id.' to '.$input->{role});

        my $build_name = $c->stash('build_name') // $c->stash('build_rs')->get_column('name')->single;
        if ($params->{send_mail} // 1) {
            $c->send_mail(
                template_file => 'build_organization_update_members',
                To => $c->construct_address_list($organization->user_accounts->order_by('user_account.name')),
                From => 'noreply@conch.joyent.us',
                Subject => 'Your Conch access has changed',
                organization => $organization->name,
                build => $build_name,
                role => $input->{role},
            );
            my @build_admins = $c->db_builds
                ->admins('with_sysadmins')
                ->search({
                    'user_account.id' => { -not_in => $organization
                        ->related_resultset('user_organization_roles')
                        ->get_column('user_id')
                        ->as_query },
                });
            $c->send_mail(
                template_file => 'build_organization_update_admins',
                To => $c->construct_address_list(@build_admins),
                From => 'noreply@conch.joyent.us',
                Subject => 'We modified an organization\'s access to your build',
                organization => $organization->name,
                build => $build_name,
                role => $input->{role},
            ) if @build_admins;
        }

        return $c->status(204);
    }

    $organization->create_related('organization_build_roles', {
        build_id => $build_id,
        role => $input->{role},
    });
    $c->log->info('Added organization '.$organization->id.' to build '.$build_id.' with the '.$input->{role}.' role');

    if ($params->{send_mail} // 1) {
        my $build_name = $c->stash('build_name') // $c->stash('build_rs')->get_column('name')->single;
        $c->send_mail(
            template_file => 'build_organization_add_members',
            To => $c->construct_address_list($organization->user_accounts->order_by('user_account.name')),
            From => 'noreply@conch.joyent.us',
            Subject => 'Your Conch access has changed',
            organization => $organization->name,
            build => $build_name,
            role => $input->{role},
        );
        my @build_admins = $c->db_builds
            ->admins('with_sysadmins')
            ->search({
                'user_account.id' => { -not_in => $organization
                    ->related_resultset('user_organization_roles')
                    ->get_column('user_id')
                    ->as_query },
            });
        $c->send_mail(
            template_file => 'build_organization_add_admins',
            To => $c->construct_address_list(@build_admins),
            From => 'noreply@conch.joyent.us',
            Subject => 'We added an organization to your build',
            organization => $organization->name,
            build => $build_name,
            role => $input->{role},
        ) if @build_admins;
    }

    $c->status(204);
}

=head2 remove_organization

Removes the indicated organization from the build.
Requires the 'admin' role on the build.

Optionally takes a query parameter C<send_mail> (defaulting to true), to send an email
to all organization members and to all build admins.

=cut

sub remove_organization ($c) {
    # Note: this method is very similar to Conch::Controller::WorkspaceUser::remove

    my $params = $c->validate_query_params('NotifyUsers');
    return if not $params;

    my $organization = $c->stash('organization_rs')->single;

    my $rs = $c->db_builds
        ->search_related('organization_build_roles', { organization_id => $organization->id });
    return $c->status(204) if not $rs->exists;

    my $build_name = $c->stash('build_name') // $c->stash('build_rs')->get_column('name')->single;
    $c->log->debug('removing organization '.$organization->name.' from build '.$build_name);

    $rs->delete;

    if ($params->{send_mail} // 1) {
        $c->send_mail(
            template_file => 'build_organization_remove_members',
            To => $c->construct_address_list($organization->user_accounts->order_by('user_account.name')),
            From => 'noreply@conch.joyent.us',
            Subject => 'Your Conch builds have been updated',
            organization => $organization->name,
            build => $build_name,
        );
        my @build_admins = $c->db_builds
            ->admins('with_sysadmins')
            ->search({ 'user_account.id' => { -not_in => $organization->user_accounts->get_column('id')->as_query } });
        $c->send_mail(
            template_file => 'build_organization_remove_admins',
            To => $c->construct_address_list(@build_admins),
            From => 'noreply@conch.joyent.us',
            Subject => 'We removed an organization from your build',
            organization => $organization->name,
            build => $build_name,
        ) if @build_admins;
    }

    return $c->status(204);
}

=head2 get_devices

Get the devices in this build.  (Includes devices located in rack(s) in this build.)
Requires the 'read-only' role on the build.

Response uses the Devices json schema.

=cut

sub get_devices ($c) {
    my $direct_devices_rs = $c->stash('build_rs')
        ->related_resultset('devices');

    # production devices do not consider location, interface data to be canonical
    my $bad_phase = $c->req->query_params->param('phase_earlier_than') // 'production';

    my $rack_devices_rs = $c->stash('build_rs')
        ->related_resultset('racks')
        ->related_resultset('device_locations')
        ->search_related('device',
            $bad_phase ? { 'device.phase' => { '<' => \[ '?::device_phase_enum', $bad_phase ] } } : ());

    # this query is carefully constructed to be efficient.
    # don't mess with it without checking with DBIC_TRACE=1.
    my $rs = $c->db_devices
        ->search({ id => [ map +{ -in => $_->get_column('id')->as_query }, $direct_devices_rs, $rack_devices_rs ] })
        ->prefetch('device_location')
        ->order_by('device.created');

    $c->status(200, [ $rs->all ]);
}

=head2 create_and_add_devices

Adds the specified device to the build (as long as it isn't in another build, or located in a
rack in another build).  The device is created if necessary with all data provided (or updated
with the data if it already exists, so the endpoint is idempotent).

Requires the 'read/write' role on the build, and the 'read-only' role on the device.

=cut

sub create_and_add_devices ($c) {
    my $input = $c->validate_request('BuildCreateDevice');
    return if not $input;

    foreach my $entry ($input->@*) {
        if (my $serial = $entry->{serial_number} and not $entry->{id}) {
            my $id = $c->db_devices->search({ serial_number => $serial })->get_column('id')->single;
            $entry->{id} = $id if $id;
        }
    }

    # we already looked up all ids for devices that were referenced only by serial_number
    my %devices = map +($_->id => $_),
        $c->db_devices->search({ 'device.id' => { -in => [ map $_->{id} // (), $input->@* ] } })
            ->prefetch({ device_location => 'rack' });

    # sku -> hardware_product
    my %hardware_products;
    if (my @skus = map $_->{sku} // (), $input->@*) {
        %hardware_products = map +($_->sku => $_),
            $c->db_hardware_products->active
                ->search({ sku => { -in => \@skus } })
                ->prefetch('hardware_product_profile');
    }

    my $build_id = $c->stash('build_id') // $c->stash('build_rs')->get_column('id')->single;

    my ($code, $payload);
    $c->txn_wrapper(sub ($c) {
        foreach my $entry ($input->@*) {
            if (not $hardware_products{$entry->{sku}}) {
                $c->log->error('no hardware_product corresponding to sku '.$entry->{sku});
                $code = 404;
                die 'rollback';
            }

            # for now, at least, many validations require this
            if (not $hardware_products{$entry->{sku}}->hardware_product_profile) {
                $c->log->error('no hardware_product_profile corresponding to sku '.$entry->{sku});
                $code = 404;
                die 'rollback';
            }

            # find device by id that we looked up before...
            if ($entry->{id}) {
                if (my $device = $devices{$entry->{id}}) {
                    if (($device->build_id and $device->build_id ne $build_id)
                        or ($device->device_location and $device->device_location->rack->build_id
                            and $device->device_location->rack->build_id ne $build_id)) {
                        $code = 409;
                        $payload = { error => 'device '.($entry->{serial_number} // $entry->{id}).' not in build '.$c->stash('build_id_or_name') };
                        die 'rollback';
                    }

                    $device->serial_number($entry->{serial_number}) if $entry->{serial_number};
                    $device->asset_tag($entry->{asset_tag}) if exists $entry->{asset_tag};
                    $device->hardware_product_id($hardware_products{$entry->{sku}}->id);
                    $device->links($entry->{links}) if exists $entry->{links};

                    if ($device->is_changed) {
                        $device->update({ updated => \'now()' });
                        $c->log->debug('updated device '.$device->serial_number
                            .' ('.$device->id.')'.' in build '.$c->stash('build_id_or_name'));
                    }
                }
                else {
                    $c->log->error('no device corresponding to device id '.$entry->{id});
                    $code = 404;
                    die 'rollback';
                }
            }
            else {
                my $device = $c->db_devices->create({
                    serial_number => $entry->{serial_number},
                    asset_tag => $entry->{asset_tag},
                    hardware_product_id => $hardware_products{$entry->{sku}}->id,
                    health => 'unknown',
                    links => $entry->{links} // [],
                    build_id => $build_id,
                });
                $devices{$device->id} = $device;
                $c->log->debug('created new device '.$entry->{serial_number}.' in build '.$c->stash('build_id_or_name'));
            }
        }
        return 1;
    })
    or return $c->status($code // 400, $payload);

    $c->status(204);
}

=head2 add_device

Adds the specified device to the build (as long as it isn't in another build, or located in a
rack in another build).

Requires the 'read/write' role on the build, and the 'read-only' role on the device.

=cut

sub add_device ($c) {
    my $device = $c->stash('device_rs')
        ->prefetch([ 'build', { device_location => { rack => 'build' } } ])
        ->single;
    my $build_id = $c->stash('build_id') // $c->stash('build_rs')->get_column('id')->single;

    if ($device->build_id) {
        return $c->status(204) if $device->build_id eq $build_id;

        $c->log->warn('cannot add device '.$c->stash('device_id').' ('.$device->serial_number
            .') to build '.$c->stash('build_id_or_name').' -- already a member of build '
            .$device->build_id.' ('.$device->build->name.')');
        return $c->status(409, { error => 'device already member of build '.$device->build_id.' ('.$device->build->name.')' });
    }

    if ($device->device_location
            and my $current_build = $device->device_location->rack->build) {
        return $c->status(204) if $current_build->id eq $build_id;

        $c->log->warn('cannot add device '.$c->stash('device_id').' ('.$device->serial_number
            .') to build '.$c->stash('build_id_or_name').' -- already a member of build '
            .$current_build->id.' ('.$device->device_location->rack->build->name
            .') via its rack location');
        return $c->status(409, { error => 'device already member of build '.$current_build->id.' ('.$current_build->name.') via rack id '.$device->device_location->rack_id });
    }

    # TODO: check other constraints..
    # - what if the build is completed?
    # - what about device.phase or rack.phase?

    $c->log->debug('adding device '.$device->id.' ('.$device->serial_number
        .') to build '.$c->stash('build_id_or_name'));
    $device->update({ build_id => $build_id, updated => \'now()' });
    return $c->status(204);
}

=head2 remove_device

Removes the specified device from the build (if it is *directly* in the build, not via a rack).

Requires the 'read/write' role on the build.

=cut

sub remove_device ($c) {
    my $rs = $c->stash('build_rs')->search_related('devices', { 'devices.id' => $c->stash('device_id') });
    if (not $rs->exists) {
        $c->log->warn('device '.$c->stash('device_id').' is not in build '.$c->stash('build_id_or_name').': cannot remove');
        return $c->status(404);
    }

    # TODO: check other constraints..
    # - what if the build is completed?
    # - what about devices located in a rack under a different build?
    # - what about device.phase or rack.phase?
    # - what if rack.build_id is set?

    $c->log->debug('removing device '.$c->stash('device_id').' from build '.$c->stash('build_id_or_name'));
    $c->stash('device_rs')->update({ build_id => undef, updated => \'now()' });
    return $c->status(204);
}

=head2 get_racks

Get the racks in this build.
Requires the 'read-only' role on the build.

Response uses the Racks json schema.

=cut

sub get_racks ($c) {
    $c->status(200, [ $c->stash('build_rs')->related_resultset('racks')->all ]);
}

=head2 add_rack

Adds the specified rack to the build (as long as it isn't in another build, or contains devices
located in another build).

Requires the 'read/write' role on the build.

=cut

sub add_rack ($c) {
    my $rack = $c->stash('rack_rs')->single;
    my $build_id = $c->stash('build_id') // $c->stash('build_rs')->get_column('id')->single;

    if ($rack->build_id) {
        return $c->status(204) if $rack->build_id eq $build_id;

        $c->log->warn('cannot add rack '.$rack->id
            .' to build '.$c->stash('build_id_or_name').' -- already a member of build '
            .$rack->build_id.' ('.$rack->build->name.')');
        return $c->status(409, { error => 'rack already member of build '.$rack->build_id.' ('.$rack->build->name.')' });
    }

    # TODO: check other constraints..
    # - what if the build is completed?
    # - what if device.build_id is set (for any devices located here)?
    # - what about device.phase or rack.phase?

    $c->log->debug('adding rack '.$rack->id.' to build '.$c->stash('build_id_or_name'));
    $rack->update({ build_id => $build_id, updated => \'now()' });
    return $c->status(204);
}

=head2 remove_rack

Requires the 'read/write' role on the build.

=cut

sub remove_rack ($c) {
    my $rs = $c->stash('build_rs')->search_related('racks', { 'racks.id' => $c->stash('rack_id') });
    if (not $rs->exists) {
        $c->log->warn('rack '.$c->stash('rack_id').' is not in build '.$c->stash('build_id_or_name').': cannot remove');
        return $c->status(404);
    }

    # TODO: check other constraints..
    # - what if the build is completed?
    # - what if device.build_id is set (for any devices located here)?
    # - what about device.phase or rack.phase?

    $c->log->debug('removing rack '.$c->stash('rack_id').' from build '.$c->stash('build_id_or_name'));
    $c->stash('rack_rs')->update({ build_id => undef, updated => \'now()' });
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
