package Conch::Controller::Rack;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use List::Util 1.55 qw(any none first uniqstr uniqint max);
use Conch::UUID 'is_uuid';

=pod

=head1 NAME

Conch::Controller::Rack

=head1 METHODS

=head2 find_rack

Chainable action that uses the C<rack_id_or_name> value provided in the stash (usually via the
request URL) to look up a rack (constraining to the datacenter_room if C<datacenter_room_rs> is
also provided) and stashes the query to get to it in C<rack_rs>.

When datacenter_room information is B<not> provided, C<rack_id_or_name> must be either a uuid
or a "long" rack name (L<Conch::DB::Result::DatacenterRoom/vendor_name>) plus
L<Conch::DB::Result::Rack/name>); otherwise, it can also be a short rack name
L<Conch::DB::Result::Rack/name>).

If C<require_role> is provided in the stash, it is used as the minimum required role for the user to
continue; otherwise the HTTP method is used to determine its value (C<HEAD> and C<GET> imply
read-only, C<POST>, C<PUT> and C<DELETE> imply read/write); or the user must be a system admin.

=cut

sub find_rack ($c) {
    my $identifier = $c->stash('rack_id_or_name');
    my $rack_rs;

    # /room/:id_or_alias/rack/:id -- ok
    # /room/:id_or_alias/rack/:longname -- ok
    # /room/:id_or_alias/rack/:shortname -- ok
    # /rack/:id -- ok
    # /rack/:longname -- ok
    # /rack/:shortname -- not ok
    if (is_uuid($identifier)) {
        $rack_rs = $c->stash('datacenter_room_rs')
            ? $c->stash('datacenter_room_rs')->related_resultset('racks')
            : $c->db_racks;
        $rack_rs = $rack_rs->search({ $rack_rs->current_source_alias.'.id' => $identifier });
    }
    elsif (my ($room_vendor_name, $rack_name) = ($identifier =~ /(.+):([^:]+)$/)) {
        # search up by long rack name
        my $room_rs = ($c->stash('datacenter_room_rs') // $c->db_datacenter_rooms)
            ->search({ 'datacenter_room.vendor_name' => $room_vendor_name });
        $rack_rs = $room_rs->search_related('racks', { 'racks.name' => $rack_name });
    }
    else {
        # search by short rack name (requires room qualifier)l
        return $c->status(400, { error => 'cannot look up rack by short name without qualifying by room' })
            if not $c->stash('datacenter_room_rs');

        $rack_rs = $c->stash('datacenter_room_rs')
            ->search_related('racks', { 'racks.name' => $identifier });
    }

    $c->log->debug('Looking for rack '.$identifier
        .($c->stash('datacenter_room_rs') ? ' in room '.$c->stash('datacenter_room_id_or_alias') : ''));

    if (not $rack_rs->exists) {
        $c->log->debug('Could not find rack '.$identifier
            .($c->stash('datacenter_room_rs') ? (' in room '.$c->stash('datacenter_room_id_or_alias')) : ''));
        return $c->status(404);
    }

    # if no minimum role was specified, use a heuristic:
    # HEAD, GET requires 'ro'; everything else (for now) requires 'rw'
    my $method = $c->req->method;
    my $requires_role = $c->stash('require_role') //
       ((any { $method eq $_ } qw(HEAD GET)) ? 'ro'
      : (any { $method eq $_ } qw(POST PUT DELETE)) ? 'rw'
      : die 'need handling for '.$method.' method');

    if (not $c->is_system_admin and not $rack_rs->user_has_role($c->stash('user_id'), $requires_role)) {
        $c->log->debug('User lacks the required role ('.$requires_role.') for rack '.$c->stash('rack_id_or_name'));
        return $c->status(403);
    }

    my $rack_id = $rack_rs->get_column($rack_rs->current_source_alias.'.id')->single;
    $c->log->debug('Found rack '.$rack_id);
    $c->stash('rack_id', $rack_id);

    $c->stash('rack_rs', $c->db_racks->search_rs({ 'rack.id' => $rack_id }));
    return 1;
}

=head2 create

Stores data as a new rack row.

=cut

sub create ($c) {
    my $input = $c->stash('request_data');

    return $c->status(409, { error => 'Room does not exist' })
        if not $c->db_datacenter_rooms->search({ id => $input->{datacenter_room_id} })->exists;

    return $c->status(409, { error => 'Rack role does not exist' })
        if not $c->db_rack_roles->search({ id => $input->{rack_role_id} })->exists;

    return $c->status(409, { error => 'Build does not exist' })
        if not $c->db_builds->search({ id => $input->{build_id} })->exists;

    return $c->status(409, { error => 'cannot add a rack to a completed build' })
        if $c->db_builds->search({ id => $input->{build_id} })->search({ completed => { '!=' => undef } })->exists;

    return $c->status(409, { error => 'The room already contains a rack named '.$input->{name} })
        if $c->db_racks->search({ datacenter_room_id => $input->{datacenter_room_id}, name => $input->{name} })->exists;

    my $rack = $c->db_racks->create($input);
    $c->log->debug('Created rack '.$rack->id);

    $c->res->headers->location('/rack/'.$rack->id);
    $c->status(201);
}

=head2 get

Get a single rack

Response uses the Rack json schema.

=cut

sub get ($c) {
    $c->res->headers->location('/rack/'.$c->stash('rack_id'));
    my $rs = $c->stash('rack_rs')
        ->with_build_name
        ->with_full_rack_name
        ->with_datacenter_room_alias
        ->with_rack_role_name;

    $c->status(200, $rs->single);
}

=head2 get_layouts

Gets all the layouts for the specified rack.

Response uses the RackLayouts json schema.

=cut

sub get_layouts ($c) {
    my @layouts = $c->stash('rack_rs')
        ->related_resultset('rack_layouts')
        ->as_subselect_rs
        ->with_rack_unit_size
        ->with_rack_name
        ->with_sku
        ->order_by('rack_unit_start')
        ->all;

    $c->log->debug('Found '.scalar(@layouts).' rack layouts');
    $c->res->headers->location('/rack/'.$c->stash('rack_id').'/layout');
    $c->status(200, \@layouts);
}

=head2 overwrite_layouts

Given the layout definitions for an entire rack, removes all existing layouts that are not in
the new definition, as well as removing any device_location assignments in those layouts.

=cut

sub overwrite_layouts ($c) {
    my $input = $c->stash('request_data');

    my %layout_sizes = map +($_->{id} => $_->{rack_unit_size}),
        $c->db_hardware_products->active->search({ id => { -in => [ map $_->{hardware_product_id}, $input->@* ] } })
            ->columns([qw(id rack_unit_size)])
            ->hri->all;

    my %desired_slots; # map of all slots that will be occupied (slot => rack_unit_start)
    foreach my $layout ($input->@*) {
        my $size = $layout_sizes{$layout->{hardware_product_id}};
        return $c->status(409, { error => 'hardware_product_id '.$layout->{hardware_product_id}.' does not exist' }) if not $size;
        my @slots = $layout->{rack_unit_start} .. $layout->{rack_unit_start} + $size - 1;
        my @overlaps = grep defined, map $desired_slots{$_}, @slots;
        return $c->status(409, { error => 'layouts starting at rack_units '.$overlaps[0].' and '.$layout->{rack_unit_start}.' overlap' }) if @overlaps;
        $desired_slots{$_} = $layout->{rack_unit_start} foreach @slots;
    }

    if (my $last_slot = max(keys %desired_slots)) {
        return $c->status(409, { error => 'layout starting at rack_unit '.$desired_slots{$last_slot}.' will extend beyond the end of the rack' })
            if $last_slot > $c->stash('rack_rs')->related_resultset('rack_role')->get_column('rack_size')->single;
    }

    my @existing_layouts = $c->stash('rack_rs')
        ->related_resultset('rack_layouts')
        ->columns([qw(hardware_product_id rack_unit_start)])
        ->hri->all;

    my @layouts_to_delete = grep {
        my $existing_layout = $_;
        none {
            $existing_layout->{hardware_product_id} eq $_->{hardware_product_id}
                and $existing_layout->{rack_unit_start} eq $_->{rack_unit_start}
        } $input->@*;
    }
    @existing_layouts;

    my @layouts_to_create = grep {
        my $new_layout = $_;
        none {
            $new_layout->{hardware_product_id} eq $_->{hardware_product_id}
                and $new_layout->{rack_unit_start} eq $_->{rack_unit_start}
        } @existing_layouts;
    }
    $input->@*;

    $c->txn_wrapper(sub ($c) {
        my $layouts_rs = $c->stash('rack_rs')
            ->search_related('rack_layouts', [ map +( +{
                    'rack_layouts.hardware_product_id' => $_->{hardware_product_id},
                    'rack_layouts.rack_unit_start' => $_->{rack_unit_start},
                } ), @layouts_to_delete ] );

        my $device_locations_rs = $layouts_rs->related_resultset('device_location');

        my $deleted_device_locations = 0+$device_locations_rs->delete;
        my $deleted_layouts = 0+$layouts_rs->delete;
        $c->db_rack_layouts->populate([ map +{ rack_id => $c->stash('rack_id'), $_->%*, }, @layouts_to_create ]);

        $c->log->debug(
            join(', ',
                ($deleted_device_locations ? ('unlocated '.$deleted_device_locations.' devices') : ()),
                ($deleted_layouts ? ('deleted '.$deleted_layouts.' rack layouts') : ()),
                (@layouts_to_create ? ('created '.scalar(@layouts_to_create).' rack layouts') : ()),
            ).' for rack '.$c->stash('rack_id'));

        return 1;
    })
    or return $c->status(400);

    $c->status(204, '/rack/'.$c->stash('rack_id').'/layout');
}

=head2 update

Update an existing rack.

=cut

sub update ($c) {
    my $input = $c->stash('request_data');

    my $rack_rs = $c->stash('rack_rs');
    my $rack = $rack_rs->single;

    if ($input->{datacenter_room_id} and $input->{datacenter_room_id} ne $rack->datacenter_room_id) {
        return $c->status(409, { error => 'Room does not exist' })
            if not $c->db_datacenter_rooms->search({ id => $input->{datacenter_room_id} })->exists;

        return $c->status(409, { error => 'New room already contains a rack named '.($input->{name} // $rack->name) })
            if $c->db_racks->search({ datacenter_room_id => $input->{datacenter_room_id}, name => $input->{name} // $rack->name })->exists;
    }
    elsif ($input->{name} and $input->{name} ne $rack->name) {
        if ($c->db_racks->search({ datacenter_room_id => $rack->datacenter_room_id, name => $input->{name} })->exists) {
            return $c->status(409, { error => 'The room already contains a rack named '.($input->{name} // $rack->name) });
        }
    }

    return $c->status(409, { error => 'Build does not exist' })
        if $input->{build_id} and not $c->db_builds->search({ id => $input->{build_id} })->exists;

    return $c->status(409, { error => 'cannot add a rack to a completed build' })
        if $input->{build_id} and (not $rack->build_id or $input->{build_id} ne $rack->build_id)
            and $c->db_builds->search({ id => $input->{build_id} })->search({ completed => { '!=' => undef } })->exists;

    return $c->status(409, { error => 'cannot add a rack to a build when in production (or later) phase' })
        if $input->{build_id} and (not $rack->build_id or $input->{build_id} ne $rack->build_id)
            and $rack->phase_cmp('production') >= 0;

    # prohibit shrinking rack_size if there are layouts that extend beyond it
    if (exists $input->{rack_role_id} and $input->{rack_role_id} ne $rack->rack_role_id) {
        my $rack_role = $c->db_rack_roles->find($input->{rack_role_id});
        return $c->status(409, { error => 'Rack role does not exist' })
            if not $rack_role;

        my @assigned_rack_units = $rack_rs->assigned_rack_units;

        if (my @out_of_range = grep $_ > $rack_role->rack_size, @assigned_rack_units) {
            $c->log->debug('found layout used by rack id '.$rack->id
                .' that has assigned rack_units greater requested new rack_size of '
                .$rack_role->rack_size.': ', join(', ', @out_of_range));
            return $c->status(409, { error => 'cannot resize rack: found an assigned rack layout that extends beyond the new rack_size' });
        }
    }

    $c->res->headers->location('/rack/'.$rack->id);

    $rack->set_columns($input);
    return $c->status(204) if not $rack->is_changed;

    $rack->update({ updated => \'now()' });
    $c->log->debug('Updated rack '.$rack->id);
    return $c->status(204);
}

=head2 delete

Delete a rack.

=cut

sub delete ($c) {
    if ($c->stash('rack_rs')->related_resultset('rack_layouts')->exists) {
        $c->log->debug('Cannot delete rack: in use by one or more rack layouts');
        return $c->status(409, { error => 'cannot delete a rack when a rack_layout is referencing it' });
    }

    $c->stash('rack_rs')->delete;
    $c->log->debug('Deleted rack '.$c->stash('rack_id'));
    return $c->status(204);
}

=head2 get_assignment

Gets all the rack layout assignments (including occupying devices) for the specified rack.

Response uses the RackAssignments json schema.

=cut

sub get_assignment ($c) {
    my @assignments = $c->stash('rack_rs')
        ->search_related('rack_layouts', undef, {
            join => [ { device_location => 'device' }, 'hardware_product' ],
            columns => {
                rack_unit_start => 'rack_layouts.rack_unit_start',
                (map +('device_'.$_ => 'device.'.$_), qw(id serial_number asset_tag)),
                hardware_product_name => 'hardware_product.name',
                sku => 'hardware_product.sku',
                rack_unit_size => 'hardware_product.rack_unit_size',
            },
        })
        ->order_by('rack_unit_start')
        ->hri
        ->all;

    $c->log->debug('Found '.scalar(@assignments).' device-rack assignments');
    $c->res->headers->location('/rack/'.$c->stash('rack_id').'/assignment');
    $c->status(200, \@assignments);
}

=head2 set_assignment

Assigns devices to rack layouts, also optionally updating serial_numbers and asset_tags (and
creating the device if needed). Existing devices in referenced slots will be unassigned as needed.

Note: the assignment is still performed even if there is no physical room in the rack
for the new hardware (its rack_unit_size overlaps into a subsequent layout), or if the device's
hardware doesn't match what the layout specifies.

=cut

sub set_assignment ($c) {
    my $input = $c->stash('request_data');

    return $c->status(409, { error => 'cannot add devices to a rack in a completed build' })
        if $c->stash('rack_rs')->related_resultset('build')->search({ completed => { '!=' => undef } })->exists;

    return $c->status(409, { error => 'cannot add devices to a rack in production (or later) phase' })
        if $c->stash('rack_rs')->search({ phase => { '>=' => 'production' } })->exists;

    # in order to determine if we have duplicate devices, we need to look up all ids for device
    # serial numbers...
    foreach my $entry ($input->@*) {
        if (my $serial = $entry->{device_serial_number} and not $entry->{device_id}) {
            my $id = $c->db_devices->search({ serial_number => $serial })->get_column('id')->single;
            $entry->{device_id} = $id if $id;
        }
    }

    return $c->status(400, { error => 'duplication of devices is not permitted' })
        if (uniqstr map $_->{device_id} // (), $input->@*) != (grep $_->{device_id}, $input->@*)
            or (uniqstr map $_->{device_serial_number} // (), $input->@*) != (grep $_->{device_serial_number}, $input->@*);
    return $c->status(400, { error => 'duplication of rack_unit_starts is not permitted' })
        if (uniqint map $_->{rack_unit_start}, $input->@*) != $input->@*;

    my @layouts = $c->stash('rack_rs')->search_related('rack_layouts',
            { 'rack_layouts.rack_unit_start' => { -in => [ map $_->{rack_unit_start}, $input->@* ] } })
        ->prefetch('device_location')
        ->order_by('rack_layouts.rack_unit_start');

    if (@layouts != $input->@*) {
        my @missing = grep {
            my $ru = $_;
            none { $ru == $_->rack_unit_start } @layouts;
        } map $_->{rack_unit_start}, $input->@*;
        return $c->status(409, { error => 'missing layout'.(@missing > 1 ? 's' : '').' for rack_unit_start '.join(', ', @missing) });
    }

    # we already looked up all ids for devices that were referenced only by serial_number
    my %devices = map +($_->id => $_),
        $c->db_devices->search({ id => { -in => [ map $_->{device_id} // (), $input->@* ] } });

    my $device_locations_rs = $c->db_device_locations->search({ rack_id => $c->stash('rack_id') });

    $c->txn_wrapper(sub ($c) {
        $c->schema->storage->dbh_do(sub ($, $dbh) { $dbh->do('set constraints all deferred') });

        # remove current occupants, if there are any (but if they are moving somewhere else
        # in the same rack, we will re-use that record for its relocation)
        $device_locations_rs->search({
            device_id => { -not_in => [ grep defined, map $_->{device_id}, $input->@* ] },
            rack_unit_start => { -in => [ map $_->{rack_unit_start}, $input->@* ] },
        })->delete;

        foreach my $entry ($input->@*) {
            my $layout = first { $_->rack_unit_start == $entry->{rack_unit_start} } @layouts;

            # find device by id that we looked up before...
            if ($entry->{device_id} and my $device = $devices{$entry->{device_id}}) {
                if ($device->phase_cmp('production') >= 0) {
                    $c->status(409, { error => 'cannot relocate devices when in production (or later) phase' });
                    die 'rollback';
                }

                $device->serial_number($entry->{device_serial_number}) if $entry->{device_serial_number};
                $device->asset_tag($entry->{device_asset_tag}) if exists $entry->{device_asset_tag};
                $device->update({ updated => \'now()' }) if $device->is_changed;

                # we'll allow this as it will be caught by a validation later on,
                # but it's probably user error of some kind.
                $c->log->warn('locating device id '.$device->id
                        .' in slot with incorrect hardware: expecting hardware_product_id '
                        .$layout->hardware_product_id.', but instead it has hardware_product_id '
                        .$device->hardware_product_id)
                    if $device->hardware_product_id ne $layout->hardware_product_id;

                next if $device_locations_rs->search({ device_id => $device->id, $entry->%{rack_unit_start} })->exists;
            }
            elsif ($entry->{device_id}) {
                $c->log->warn('Could not find device '.$entry->{device_id});
                $c->status(404);
                die 'rollback';
            }
            else {
                my $device = $c->db_devices->create({
                    serial_number => $entry->{device_serial_number},
                    asset_tag => $entry->{device_asset_tag},
                    hardware_product_id => $layout->hardware_product_id,
                    health => 'unknown',
                    build_id => $c->stash('rack_rs')->get_column('build_id')->single,
                });
                $entry->{device_id} = $device->id;
            }

            $c->db_device_locations->update_or_create(
                {
                    rack_id => $c->stash('rack_id'),
                    $entry->%{qw(device_id rack_unit_start)},
                    updated => \'now()',
                },
                { key => 'primary' },   # only search for conflicts by device_id
            );
        }

        return 1;
    })
    or do {
        $c->status(400) if not $c->res->code;
        return;
    };

    $c->log->debug('Updated device assignments for rack '.$c->stash('rack_id'));
    $c->status(204, '/rack/'.$c->stash('rack_id').'/assignment');
}

=head2 delete_assignment

=cut

sub delete_assignment ($c) {
    my $input = $c->stash('request_data');

    my @layouts = $c->stash('rack_rs')->search_related('rack_layouts',
            { 'rack_layouts.rack_unit_start' => { -in => [ map $_->{rack_unit_start}, $input->@* ] } })
        ->prefetch('device_location')
        ->order_by('rack_layouts.rack_unit_start');

    if (@layouts != $input->@*) {
        my @missing = grep {
            my $ru = $_;
            none { $ru == $_->rack_unit_start } @layouts;
        } map $_->{rack_unit_start}, $input->@*;
        $c->log->debug('Cannot delete nonexistent layout for rack_unit_start '.join(', ', @missing));
        return $c->status(404);
    }

    if (my @unoccupied = grep !$_->device_location, @layouts) {
        $c->log->debug('Cannot delete assignment for unoccupied slot at rack_unit_start '
            .join(', ', map $_->rack_unit_start, @unoccupied));
        return $c->status(404);
    }

    foreach my $entry ($input->@*) {
        my $layout = first { $_->rack_unit_start == $entry->{rack_unit_start} } @layouts;
        if ($layout->device_location->device_id ne $entry->{device_id}) {
            $c->log->debug('rack_unit_start '.$layout->rack_unit_start
                .' occupied by device_id '.$layout->device_location->device_id
                .' but was expecting device_id '.$entry->{device_id});
            $c->status(404);
        }
    }

    return if $c->res->code;

    my $deleted = $c->db_device_locations->search({
        rack_id => $c->stash('rack_id'),
        rack_unit_start => { -in => [ map $_->{rack_unit_start}, $input->@* ] },
    })->delete;

    $c->log->debug('deleted '.$deleted.' device-rack assignment'.($deleted > 1 ? 's' : ''));

    return $c->status(204);
}

=head2 set_phase

Updates the phase of this rack, and optionally all devices located in this rack.

Use the C<rack_only> query parameter to specify whether to only update the rack's phase, or all
located devices' phases as well.

=cut

sub set_phase ($c) {
    my $params = $c->stash('query_params');
    my $input = $c->stash('request_data');

    my $rack = $c->stash('rack_rs')->single;
    $rack->set_columns($input);

    $rack->update({ updated => \'now()' }) if $rack->is_changed;
    $c->log->debug('set the phase for rack '.$rack->id.' to '.$input->{phase});

    if (not $params->{rack_only}) {
        $c->stash('rack_rs')
            ->related_resultset('device_locations')
            ->related_resultset('device')
            ->update({ phase => $input->{phase}, updated => \'now()' });

        $c->log->debug('set the phase for all devices in rack '.$c->stash('rack_id').' to '.$input->{phase});
    }

    $c->status(204, '/rack/'.$c->stash('rack_id'));
}

=head2 add_links

Appends the provided link(s) to the rack.

=cut

sub add_links ($c) {
  my $input = $c->stash('request_data');

  # only perform the update if not all links are already present
  $c->stash('rack_rs')
    ->search(\[ 'not(links @> ?)', [{},$input->{links}] ])
    ->update({
        links => \[ 'array_cat_distinct(links,?)', [{},$input->{links}] ],
        updated => \'now()',
    });

  my $rack_id = $c->stash('rack_id') // $c->stash('rack_rs')->get_column('id')->single;
  $c->status(204, '/rack/'.$rack_id);
}

=head2 remove_links

When a payload is specified, remove specified links from the rack;
with a null payload, removes all links.

=cut

sub remove_links ($c) {
  my $input = $c->stash('request_data');

  if ($input) {
    $c->stash('rack_rs')
      # we do this instead of '? = any(links)' in order to take
      # advantage of the built-in GIN indexing on the @> operator
      ->search(\[ 'links @> ?', [{},$input->{links}] ])
      ->update({
        links => \[ 'array_subtract(links,?)', [{},$input->{links}] ],
        updated => \'now()',
      });
  }
  else {
    $c->stash('rack_rs')
      ->search({ links => { '!=' => '{}' } })
      ->update({ links => '{}', updated => \'now()' });
  }

  my $rack_id = $c->stash('rack_id') // $c->stash('rack_rs')->get_column('id')->single;
  $c->status(204, '/rack/'.$rack_id);
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
