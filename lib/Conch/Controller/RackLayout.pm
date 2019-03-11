package Conch::Controller::RackLayout;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Role::Tiny::With;
with 'Conch::Role::MojoLog';

use List::Util 'any';

=pod

=head1 NAME

Conch::Controller::RackLayout

=head1 METHODS

=head2 find_rack_layout

Supports rack layout lookups by id

=cut

sub find_rack_layout ($c) {
    unless($c->is_system_admin) {
        return $c->status(403);
    }

    my $layout = $c->db_rack_layouts->find($c->stash('layout_id'));
    if (not $layout) {
        $c->log->debug('Could not find rack layout '.$c->stash('layout_id'));
        return $c->status(404 => { error => 'Not found' });
    }

    $c->log->debug('Found rack layout '.$layout->id);
    $c->stash('rack_layout' => $layout);
    return 1;
}

=head2 create

Creates a new rack_layout entry according to the passed-in specification.

=cut

sub create ($c) {
    return $c->status(403) unless $c->is_system_admin;
    my $input = $c->validate_input('RackLayoutCreate');
    return if not $input;

    $input->{hardware_product_id} = delete $input->{product_id};
    $input->{rack_unit_start} = delete $input->{ru_start};

    unless ($c->db_racks->search({ id => $input->{rack_id} })->exists) {
        $c->log->debug('Could not find rack '.$input->{rack_id});
        return $c->status(400 => { error => 'Rack does not exist' });
    }

    unless ($c->db_hardware_products->active->search({ id => $input->{hardware_product_id} })->exists) {
        $c->log->debug('Could not find hardware product '.$input->{hardware_product_id});
        return $c->status(400 => { error => 'Hardware product does not exist' });
    }

    my $rack_size = $c->db_rack_roles->search(
        { 'racks.id' => $input->{rack_id} },
        { join => 'racks' },
    )->get_column('rack_size')->single;

    if ($input->{rack_unit_start} > $rack_size) {
        $c->log->debug("ru_start $input->{rack_unit_start} starts beyond the end of the rack (size $rack_size)");
        return $c->status(400 => { error => 'ru_start beyond maximum' });
    }

    my %assigned_rack_units = map { $_ => 1 }
        $c->db_racks->search({ 'rack.id' => $input->{rack_id} })
        ->assigned_rack_units;

    my $new_rack_unit_size = $c->db_hardware_products
        ->search({ 'hardware_product.id' => $input->{hardware_product_id} })
        ->related_resultset('hardware_product_profile')
        ->get_column('rack_unit')->single;

    return $c->status(400, { error => 'missing hardware product profile on hardware product id '.$input->{hardware_product_id} })
        if not $new_rack_unit_size;

    if ($input->{rack_unit_start} + $new_rack_unit_size - 1 > $rack_size) {
        $c->log->debug('layout ends at rack unit '.($input->{rack_unit_start} + $new_rack_unit_size - 1)
            .", beyond the end of the rack (size $rack_size)");
        return $c->status(400 => { error => 'ru_start+rack_unit_size beyond maximum' });
    }

    my @desired_positions = $input->{rack_unit_start} .. ($input->{rack_unit_start} + $new_rack_unit_size - 1);

    if (any { $assigned_rack_units{$_} } @desired_positions) {
        $c->log->debug('Rack unit position '.$input->{rack_unit_start} . ' is already assigned');
        return $c->status(400 => { error => 'ru_start conflict' });
    }

    my $layout = $c->db_rack_layouts->create($input);
    $c->log->debug('Created rack layout '.$layout->id);

    $c->status(303 => '/layout/'.$layout->id);
}

=head2 get

Gets one specific rack layout.

Response uses the RackLayout json schema.

=cut

sub get ($c) {
    $c->status(200, $c->stash('rack_layout'));
}

=head2 get_all

Gets *all* rack layouts.

Response uses the RackLayouts json schema.

=cut

sub get_all ($c) {
    return $c->status(403) unless $c->is_system_admin;

    # TODO: to be more helpful to the UI, we should include the width of the hardware that is
    # assigned to each rack_unit(s).

    my @layouts = $c->db_rack_layouts
        #->search(undef, {
        #    join => { 'hardware_product' => 'hardware_product_profile' },
        #    '+columns' => { rack_unit_size =>  'hardware_product_profile.rack_unit' },
        #    collapse => 1,
        #})
        ->order_by([ qw(rack_id rack_unit_start) ])
        ->all;

    $c->log->debug('Found '.scalar(@layouts).' rack layouts');
    $c->status(200 => \@layouts);
}

=head2 update

Updates a rack layout to specify that a certain hardware product should reside at a certain
rack starting position.

=cut

sub update ($c) {
    my $input = $c->validate_input('RackLayoutUpdate');
    return if not $input;

    $input->{hardware_product_id} = delete $input->{product_id} if exists $input->{product_id};
    $input->{rack_unit_start} = delete $input->{ru_start} if exists $input->{ru_start};

    # if changing rack...
    if ($input->{rack_id} and $input->{rack_id} ne $c->stash('rack_layout')->rack_id) {
        $c->log->debug('Cannot move a layout to a new rack. Delete this layout and create a new one at the new location');
        return $c->status(400 => { error => 'cannot change rack_id' });
    }

    # cannot alter an occupied layout
    if (my $device_location = $c->stash('rack_layout')->device_location) {
        $c->log->debug('Cannot update layout: occupied by device id '.$device_location->device_id);
        return $c->status(400 => { error => 'cannot update a layout with a device occupying it' });
    }

    # if changing hardware_product_id...
    if ($input->{hardware_product_id} and $input->{hardware_product_id} ne $c->stash('rack_layout')->hardware_product_id) {
        unless ($c->db_hardware_products->active->search({ id => $input->{hardware_product_id} })->exists) {
            return $c->status(400 => { error => 'Hardware product does not exist' });
        }
    }

    my $rack_size = $c->db_rack_roles->search(
        { 'racks.id' => $c->stash('rack_layout')->rack_id },
        { join => 'racks' },
    )->get_column('rack_size')->single;

    # if changing rack location...
    if ($input->{rack_unit_start} and $input->{rack_unit_start} != $c->stash('rack_layout')->rack_unit_start) {
        if ($c->db_rack_layouts->search({
                    rack_id => $c->stash('rack_layout')->rack_id,
                    rack_unit_start => $input->{rack_unit_start},
                })->exists) {
            $c->log->debug('Conflict with ru_start value of '.$input->{rack_unit_start});
            return $c->status(400 => { error => 'ru_start conflict' });
        }

        if ($input->{rack_unit_start} > $rack_size) {
            $c->log->debug("ru_start $input->{rack_unit_start} starts beyond the end of the rack (size $rack_size)");
            return $c->status(400 => { error => 'ru_start beyond maximum' });
        }
    }

    # determine assigned slots, not counting the slots currently assigned to this layout (which
    # we will be giving up)

    my %assigned_rack_units = map { $_ => 1 } $c->stash('rack_layout')
        ->related_resultset('rack')->assigned_rack_units;

    my $current_rack_unit_size = $c->db_hardware_products->search(
        { 'hardware_product.id' => $c->stash('rack_layout')->hardware_product_id })
        ->related_resultset('hardware_product_profile')->get_column('rack_unit')->single;

    return $c->status(400, { error => 'missing hardware product profile on hardware product id '.$c->stash('rack_layout')->hardware_product_id })
        if not $current_rack_unit_size;

    delete @assigned_rack_units{
        $c->stash('rack_layout')->rack_unit_start ..
        ($c->stash('rack_layout')->rack_unit_start + $current_rack_unit_size - 1)
    };

    my $new_rack_unit_size = $input->{hardware_product_id}
        ? $c->db_hardware_products->search({ 'hardware_product.id' => $input->{hardware_product_id} })
            ->related_resultset('hardware_product_profile')->get_column('rack_unit')->single
        : $current_rack_unit_size;

    return $c->status(400, { error => 'missing hardware product profile on hardware product id '.$input->{hardware_product_id} })
        if not $new_rack_unit_size;

    my $new_rack_unit_start = $input->{rack_unit_start} // $c->stash('rack_layout')->rack_unit_start;

    if ($new_rack_unit_start + $new_rack_unit_size - 1 > $rack_size) {
        $c->log->debug('layout ends at rack unit '.($new_rack_unit_start + $new_rack_unit_size - 1)
            .", beyond the end of the rack (size $rack_size)");
        return $c->status(400 => { error => 'ru_start+rack_unit_size beyond maximum' });
    }

    my @desired_positions = $new_rack_unit_start .. ($new_rack_unit_start + $new_rack_unit_size - 1);

    if (any { $assigned_rack_units{$_} } @desired_positions) {
        $c->log->debug('Rack unit position '.$input->{rack_unit_start} . ' is already assigned');
        return $c->status(400 => { error => 'ru_start conflict' });
    }

    $c->stash('rack_layout')->update({ %$input, updated => \'now()' });

    return $c->status(303 => '/layout/'.$c->stash('rack_layout')->id);
}

=head2 delete

Deletes the specified rack layout.

=cut

sub delete ($c) {
    if (my $device_location = $c->stash('rack_layout')->device_location) {
        $c->log->debug('Cannot delete layout: occupied by device id '.$device_location->device_id);
        return $c->status(400 => { error => 'cannot delete a layout with a device occupying it' });
    }

    $c->stash('rack_layout')->delete;
    $c->log->debug('Deleted rack layout '.$c->stash('rack_layout')->id);
    return $c->status(204);
}

1;
__END__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.

=cut
# vim: set ts=4 sts=4 sw=4 et :
