package Conch::Controller::DeviceReport;

use Mojo::Base 'Mojolicious::Controller', -signatures;

=pod

=head1 NAME

Conch::Controller::DeviceReport

=head1 DESCRIPTION

Controller for processing and managing device reports.

=head1 METHODS

=head2 process

Processes the device report, turning it into the various device_ tables as well
as running validations

Response uses the ValidationStateWithResults json schema.

=cut

sub process ($c) {
    my $unserialized_report = $c->validate_request('DeviceReport');
    return if not $unserialized_report;

    # Make sure the API and device report agree on who we're talking about
    if ($c->stash('device_serial_number') ne $unserialized_report->{serial_number}) {
        return $c->status(422, { error => 'Serial number provided to the API does not match the report data.' });
    }

    # Make sure that the remote side is telling us about a hardware product we understand
    my $hardware_product_id = $c->db_hardware_products->active->search({ sku => $unserialized_report->{sku} })->get_column('id')->single;
    return $c->status(409, { error => 'Could not locate hardware product for sku '.$unserialized_report->{sku} }) if not $hardware_product_id;

    return $c->status(409, { error => 'Hardware product does not contain a profile' })
        if not $c->db_hardware_product_profiles->active->search({ hardware_product_id => $hardware_product_id })->exists;

    if ($unserialized_report->{relay} and my $relay_serial = $unserialized_report->{relay}{serial}) {
        return $c->status(409, { error => 'relay serial '.$relay_serial.' is not registered' })
            if not $c->db_relays->active->search({ serial_number => $relay_serial })->exists;
    }

    my $device = $c->db_devices->find({ serial_number => $c->stash('device_serial_number') });
    if (not $device) {
        $c->log->error('Failed to find device '.$c->stash('device_serial_number'));
        return $c->status(404);
    }

    if ($hardware_product_id ne $device->hardware_product_id) {
        $device->health('error');
        $device->update({ updated => \'now()' }) if $device->is_changed;
        return $c->status(409, { error => 'Report sku does not match expected hardware_product for device '.$c->stash('device_serial_number') });
    }

    # capture information about the last report before we store the new one
    # state can be: error, fail, pass, where no validations on a valid report is
    # considered to be a pass.
    my $previous_report = $device->self_rs->latest_device_report
        ->columns('device_reports.id')
        ->with_report_status
        ->hri
        ->single;
    my ($previous_report_id, $previous_report_status) = $previous_report ? $previous_report->@{qw(id status)} : ();

    # Update the device and create the device report
    $c->log->debug('Updating device '.$c->stash('device_serial_number'));
    my $prev_uptime = $device->uptime_since;
    $c->txn_wrapper(sub ($c) {
        $device->update({
            system_uuid         => $unserialized_report->{system_uuid},
            last_seen           => \'now()',
            exists $unserialized_report->{uptime_since} ? ( uptime_since => $unserialized_report->{uptime_since} ) : (),
            hostname            => $unserialized_report->{os}{hostname},
            $unserialized_report->{links}
                ? ( links => \['array_cat_distinct(links,?)', [{},$unserialized_report->{links}]] ) : (),
            updated             => \'now()',
        });
    });

    if ($c->res->code) {
        $device->discard_changes;
        $device->health('error');
        $device->update({ updated => \'now()' }) if $device->is_changed;
        return $c->status(400, { error => 'could not process report for device '
            .$c->stash('device_serial_number')
            .($c->stash('exception') ? ': '.(split(/\n/, $c->stash('exception'), 2))[0] : '') });
    }

    $c->log->debug('Storing device report for device '.$c->stash('device_serial_number'));
    my $device_report = $device->create_related('device_reports', {
        report    => $c->req->text, # this is the raw json string
        # we will always keep this report if the previous report failed, or this is the first
        # report (in its phase).
        !$previous_report_status || $previous_report_status ne 'pass' ? ( retain => 1 ) : (),
        # invalid, created use defaults.
    });
    $c->log->info('Created device report '.$device_report->id);


    $c->log->debug('Recording device configuration');
    $c->txn_wrapper(\&_record_device_configuration, $prev_uptime, $device, $unserialized_report);

    if ($c->res->code) {
        $device->health('error');
        $device->update({ updated => \'now()' }) if $device->is_changed;
        return;
    }

    # Time for validations http://www.space.ca/wp-content/uploads/2017/05/giphy-1.gif
    my $validation_plan = $c->db_validation_plans->search({
        id => { '=' => $c->db_hardware_products->search({ id => $hardware_product_id })->get_column('validation_plan_id')->as_query },
    })->single;
    $c->log->debug('Running validation plan '.$validation_plan->id.': '.$validation_plan->name.'"');

    my $validation_state = Conch::ValidationSystem->new(
        schema => $c->schema,
        log => $c->log,
    )->run_validation_plan(
        validation_plan => $validation_plan,
        # TODO: to eliminate needless db queries, we should prefetch all the relationships
        # that various validations will request, e.g. device_location, hardware_product etc
        device => $c->db_ro_devices->find($device->id),
        device_report => $device_report,
    );

    if (not $validation_state) {
        $device->health('error');
        $device->update({ updated => \'now()' }) if $device->is_changed;
        return $c->status(400, { error => 'no validations ran'
            .($c->stash('exception') ? ': '.(split(/\n/, $c->stash('exception'), 2))[0] : '') });
    }
    $c->log->debug('Validations ran with result: '.$validation_state->status);

    # calculate the device health based on the validation results.
    # currently, since there is just one (hardcoded) plan per device, we can simply copy it
    # from the validation_state, but in the future we should query for the most recent
    # validation_state of each plan type and use the cumulative results to determine health.
    $device->health($validation_state->status);
    $device->update({ updated => \'now()' }) if $device->is_changed;

    # save some state about this report that will help us out next time, when we consider
    # deleting it... we always keep all failing reports (we also keep the first report after a
    # failure)
    $device_report->update({ retain => 1 })
        if $validation_state->status ne 'pass' and not $device_report->retain;

    # now delete that previous report, if we can
    if ($validation_state->status eq 'pass'
            and $previous_report_id and $previous_report_status eq 'pass') {
        if ($c->db_device_reports
            ->search({ id => $previous_report_id, retain => \'is not TRUE' })
            ->delete > 0)
        {
            $c->log->debug('deleted previous device report id '.$previous_report_id);
            # deleting device_report cascaded to validation_state and validation_state_member,
            # but we leave orphaned validation_result rows behind for performance reasons.
        }
    }

    # prime the resultset cache for the serializer
    $validation_state->prefetch_validation_results;

    $c->res->headers->location($c->url_for('/device/'.$device->id));
    $c->status(200, $validation_state);
}

=head2 _record_device_configuration

Uses a device report to populate configuration information about the given device

=cut

sub _record_device_configuration ($c, $prev_uptime, $device, $dr) {
    # Add a reboot count if there's not a previous uptime but one in this
    # report (i.e. first uptime reported), or if the previous uptime date is
    # less than the current one (i.e. there has been a reboot)
    _add_reboot_count($device)
        if (!$prev_uptime && $device->uptime_since)
        || $device->uptime_since && $prev_uptime < $device->uptime_since;

    if ($dr->{relay}) {
        my $relay_rs = $c->db_relays->active->search({ serial_number => $dr->{relay}{serial} });
        $relay_rs->update({ last_seen => \'now()' });
        if (my $drc = $relay_rs
                ->search_related('device_relay_connections' => { device_id => $device->id })
                ->single) {
            $drc->update({ last_seen => \'now()' });
        }
        else {
            $c->db_device_relay_connections->create({
                device_id => $device->id,
                relay_id => $relay_rs->get_column('id')->as_query,
            });
        }
    }
    else {
        $c->log->warn('received report without relay id (device_id '. $device->id.')');
    }

    # Keep track of which disk serials have been previously recorded in the
    # DB but are no longer being reported due to a disk swap, etc.
    my @device_disk_serials = $device->related_resultset('device_disks')
        ->active->get_column('serial_number')->all;
    my %inactive_serials;
    @inactive_serials{@device_disk_serials} = ();

    foreach my $disk (keys $dr->{disks}->%*) {
        $c->log->debug('Device '.$device->id.': Recording disk: '.$disk);

        delete $inactive_serials{$disk};

        # if disk already exists on a different device, it will be relocated
        $c->db_device_disks->update_or_create(
            {
                device_id => $device->id,
                serial_number => $disk,
                $dr->{disks}{$disk}->%{qw(
                    slot
                    size
                    vendor
                    model
                    firmware
                    transport
                    health
                    drive_type
                    enclosure
                    hba
                )},
                deactivated   => undef,
                updated       => \'now()'
            },
            { key => 'device_disk_serial_number_key' },
        );
    }

    my @inactive_serials = keys %inactive_serials;

    # deactivate all disks that were previously recorded but are no longer
    # reported in the device report
    if (@inactive_serials) {
        $c->db_device_disks->search({ serial_number => { -in => \@inactive_serials } })->deactivate;
    }

    $dr->{disks}
        and $c->log->info('Recorded disk info for Device '.$device->id);


    my @device_nic_macs = $device->device_nics->active->get_column('mac')->all;
    my %inactive_macs; @inactive_macs{@device_nic_macs} = ();

    # deactivate all the nics that are currently located with other devices,
    # so we can relocate them to this device
    $c->db_device_nics->active->search({
        device_id => { '!=' => $device->id },
        mac => { -in => [ map $_->{mac}, values $dr->{interfaces}->%* ] },
    })->deactivate;

    foreach my $nic (keys $dr->{interfaces}->%*) {
        my $mac = $dr->{interfaces}{$nic}{mac};

        $c->log->debug('Device '.$device->id.': Recording NIC: '.$mac);
        delete $inactive_macs{$mac};

        # deactivate this iface_name where mac is different,
        # so we can assign it the new mac.
        $c->db_device_nics->active->search({
            device_id => $device->id,
            iface_name => $nic,
            mac => { '!=' => $mac },
        })->deactivate;

        # if nic already exists on a different device, it will be relocated
        $c->db_device_nics->update_or_create(
            {
                device_id    => $device->id,
                mac          => $mac,
                iface_name   => $nic,
                iface_driver => '',
                iface_type   => $dr->{interfaces}->{$nic}->{product},
                iface_vendor => $dr->{interfaces}->{$nic}->{vendor},
                state        => $dr->{interfaces}->{$nic}->{state},
                ipaddr       => $dr->{interfaces}->{$nic}->{ipaddr},
                mtu          => $dr->{interfaces}->{$nic}->{mtu},
                updated      => \'now()',
                deactivated  => undef,
            },
        );

        my $nic_peers = $c->db_device_neighbors->update_or_create(
            {
                mac         => $mac,
                raw_text    => $dr->{interfaces}->{$nic}->{peer_text},
                peer_switch => $dr->{interfaces}->{$nic}->{peer_switch},
                peer_port   => $dr->{interfaces}->{$nic}->{peer_port},
                peer_mac    => $dr->{interfaces}->{$nic}->{peer_mac},
                updated     => \'now()'
            }
        );
    }

    my @inactive_macs = keys %inactive_macs;

    # deactivate all nics that were previously recorded but are no longer
    # reported in the device report
    if (@inactive_macs) {
        $c->db_device_nics->search({ mac => { -in => \@inactive_macs } })->deactivate;
    }
}

sub _add_reboot_count ($device) {
    my $reboot_count = $device->find_or_new_related('device_settings', {
        deactivated => undef,
        name => 'reboot_count'
    });

    if ($reboot_count->in_storage) {
        $reboot_count->update({
            value => 1 + $reboot_count->value,
            updated => \'now()',
        });
    }
    else {
        $reboot_count->value(0);
        $reboot_count->insert;
    }
}

=head2 find_device_report

Chainable action that validates the 'device_report_id' provided in the path.
Stores the device_id and device_report resultset to the stash for later retrieval.

Role checks are done in the next controller action in the chain.

=cut

sub find_device_report ($c) {
    my $device_report_rs = $c->db_device_reports
        ->search_rs({ 'device_report.id' => $c->stash('device_report_id') });

    my $device_id = $device_report_rs->get_column('device_id')->single;
    if (not $device_id) {
        $c->log->debug('Failed to find device_report id \''.$c->stash('device_report_id').'\'');
        return $c->status(404);
    }

    $c->stash('device_id', $device_id);
    $c->stash('device_report_rs', $device_report_rs);

    return 1;
}

=head2 get

Get the device_report record specified by uuid.
A role check has already been done by L<device#find_device|Conch::Controller::Device/find_device>.

Response uses the DeviceReportRow json schema.

=cut

sub get ($c) {
    return $c->status(200, $c->stash('device_report_rs')->single);
}

=head2 validate_report

Process a device report without writing anything to the database; otherwise behaves like
L</process>. The described device does not have to exist.

Response uses the ReportValidationResults json schema.

=cut

sub validate_report ($c) {
    my $unserialized_report = $c->validate_request('DeviceReport');
    if (not $unserialized_report) {
        $c->log->debug('Device report input did not match json schema specification');
        return;
    }

    my $hardware_product_id = $c->db_hardware_products->active->search({ sku => $unserialized_report->{sku} })->get_column('id')->single;
    return $c->status(409, { error => 'Could not locate hardware product for sku '.$unserialized_report->{sku} }) if not $hardware_product_id;

    return $c->status(409, { error => 'Hardware product does not contain a profile' })
        if not $c->db_hardware_product_profiles->active->search({ hardware_product_id => $hardware_product_id })->exists;

    if (my $current_hardware_product_id = $c->db_devices->search({ serial_number => $unserialized_report->{serial_number} })->get_column('hardware_product_id')->single) {
        return $c->status(409, { error => 'Report sku does not match expected hardware_product for device '.$unserialized_report->{serial_number} })
            if $current_hardware_product_id ne $hardware_product_id;
    }

    my $validation_plan = $c->db_validation_plans->search({
        id => { '=' => $c->db_hardware_products->search({ id => $hardware_product_id })->get_column('validation_plan_id')->as_query },
    })->single;
    $c->log->debug('Running validation plan '.$validation_plan->id.': '.$validation_plan->name.'"');

    my ($status, @validation_results);
    $c->txn_wrapper(sub ($c) {
        my $device = $c->db_devices->update_or_create({
            serial_number       => $unserialized_report->{serial_number},
            system_uuid         => $unserialized_report->{system_uuid},
            hardware_product_id => $hardware_product_id,
            health              => 'unknown',
            last_seen           => \'now()',
            uptime_since        => $unserialized_report->{uptime_since},
            hostname            => $unserialized_report->{os}{hostname},
            updated             => \'now()',
        },
        { key => 'device_serial_number_key' });

        # we do not call _record_device_configuration, because no validations
        # should be using that information, instead choosing to respect the report data.

        ($status, @validation_results) = Conch::ValidationSystem->new(
            schema => $c->ro_schema,
            log => $c->log,
        )->run_validation_plan(
            validation_plan => $validation_plan,
            device => $device,
            data => $unserialized_report,
            no_save_db => 1,
        );

        die 'rollback: device used for report validation should not be persisted';
    });

    return $c->status(400, { error => 'no validations ran'
            .($c->stash('exception') ? ': '.(split(/\n/, $c->stash('exception'), 2))[0] : '') })
        if not @validation_results;

    $c->status(200, {
        device_serial_number => $unserialized_report->{serial_number},
        validation_plan_id => $validation_plan->id,
        status => $status,
        results => \@validation_results,
    });
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
