package Conch::Controller::RackLayout;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use List::Util 'any';
use Conch::UUID 'is_uuid';

=pod

=head1 NAME

Conch::Controller::RackLayout

=head1 METHODS

=head2 find_rack_layout

Chainable action that uses the C<layout_id_or_rack_unit_start> value provided in the stash
(usually via the request URL) to look up a layout, and stashes the query to get to it in
C<layout_rs>.

=cut

sub find_rack_layout ($c) {
    my $identifier = $c->stash('layout_id_or_rack_unit_start');

    # .../rack/.../layout/:id -- ok
    # .../rack/.../layout/:rack_unit_start -- ok
    # /layout/:id -- ok
    # /layout/:rack_unit_start -- not ok

    my $layout_rs;
    if (is_uuid($identifier)) {
        $layout_rs = $c->db_rack_layouts->search({
            $c->stash('rack_id') ? ( 'rack_layout.rack_id' => $c->stash('rack_id') ) : (),
            'rack_layout.id' => $identifier,
        });
    }
    elsif ($identifier =~ /^[0-9]+$/) {
        return $c->status(400, { error => 'cannot look up layout by rack_unit_start without qualifying by rack' }) if not $c->stash('rack_id');
        $layout_rs = $c->db_rack_layouts->search({
            'rack_layout.rack_id' => $c->stash('rack_id'),
            'rack_layout.rack_unit_start' => $identifier,
        });
    }
    else {
        return $c->status(400, { error => 'invalid layout identifier '.$identifier });
    }

    if (not $layout_rs->exists) {
        $c->log->debug('Could not find rack layout '.$identifier
            .($c->stash('rack_id') ? ' in rack id '.$c->stash('rack_id') : ''));
        return $c->status(404);
    }

    $c->log->debug('Found rack layout '.$identifier
        .($c->stash('rack_id') ? ' in rack id '.$c->stash('rack_id') : ''));
    $c->stash('rack_layout_rs', $layout_rs);
    return 1;
}

=head2 create

Creates a new rack_layout entry according to the passed-in specification.

=cut

sub create ($c) {
    my $input = $c->stash('request_data');

    if (not $c->db_racks->search({ id => $input->{rack_id} })->exists) {
        $c->log->debug('Could not find rack '.$input->{rack_id});
        return $c->status(409, { error => 'Rack does not exist' });
    }

    if (not $c->db_hardware_products->active->search({ id => $input->{hardware_product_id} })->exists) {
        $c->log->debug('Could not find hardware product '.$input->{hardware_product_id});
        return $c->status(409, { error => 'Hardware product does not exist' });
    }

    my $rack_size = $c->db_rack_roles->search(
        { 'racks.id' => $input->{rack_id} },
        { join => 'racks' },
    )->get_column('rack_size')->single;

    if ($input->{rack_unit_start} > $rack_size) {
        $c->log->debug("rack_unit_start $input->{rack_unit_start} starts beyond the end of the rack (size $rack_size)");
        return $c->status(409, { error => 'rack_unit_start beyond maximum' });
    }

    my $new_rack_unit_size = $c->db_hardware_products
        ->search({ 'hardware_product.id' => $input->{hardware_product_id} })
        ->get_column('rack_unit_size')->single;

    if ($input->{rack_unit_start} + $new_rack_unit_size - 1 > $rack_size) {
        $c->log->debug('layout ends at rack unit '.($input->{rack_unit_start} + $new_rack_unit_size - 1)
            .", beyond the end of the rack (size $rack_size)");
        return $c->status(409, { error => 'rack_unit_start+rack_unit_size beyond maximum' });
    }

    my %assigned_rack_units = map +($_ => 1),
        $c->db_racks->search({ 'rack.id' => $input->{rack_id} })->assigned_rack_units;

    my @desired_slots = $input->{rack_unit_start} .. ($input->{rack_unit_start} + $new_rack_unit_size - 1);

    if (any { $assigned_rack_units{$_} } @desired_slots) {
        $c->log->debug('Rack unit slot '.$input->{rack_unit_start}.' is already assigned');
        return $c->status(409, { error => 'rack_unit_start conflict' });
    }

    my $layout = $c->db_rack_layouts->create($input);
    $c->log->debug('Created rack layout '.$layout->id);

    $c->status(303, '/layout/'.$layout->id);
}

=head2 get

Gets one specific rack layout.

Response uses the RackLayout json schema.

=cut

sub get ($c) {
    my $layout = $c->stash('rack_layout_rs')
        ->with_rack_unit_size
        ->with_rack_name
        ->with_sku
        ->single;

    $c->res->headers->location('/layout/'.$layout->id);
    $c->status(200, $layout);
}

=head2 get_all

Gets B<all> rack layouts.

Response uses the RackLayouts json schema.

=cut

sub get_all ($c) {
    my @layouts = $c->db_rack_layouts
        ->with_rack_unit_size
        ->with_rack_name
        ->with_sku
        ->order_by([ qw(rack.name rack_unit_start) ])
        ->all;

    $c->log->debug('Found '.scalar(@layouts).' rack layouts');
    $c->status(200, \@layouts);
}

=head2 update

Updates a rack layout to specify that a certain hardware product should reside at a certain
rack starting position.

=cut

sub update ($c) {
    my $input = $c->stash('request_data');
    my $layout = $c->stash('rack_layout_rs')->single;

    # only permit updating occupied layouts if the hardware_product_id is the only change,
    # iff it is changing to the device_hardware_product_id.
    if (my $device = $layout->related_resultset('device_location')
        ->related_resultset('device')->columns([qw(id hardware_product_id)])->single) {
      if (($input->{rack_unit_start} and $input->{rack_unit_start} != $layout->rack_unit_start)
        or ($input->{hardware_product_id}
          and $input->{hardware_product_id} ne $layout->hardware_product_id
          and $input->{hardware_product_id} ne $device->hardware_product_id)) {
        $c->log->debug('Cannot update layout: occupied by device id '.$device->id);
        return $c->status(409, { error => 'cannot update a layout with a device occupying it' });
      }
    }

    # if changing hardware_product_id...
    if ($input->{hardware_product_id} and $input->{hardware_product_id} ne $layout->hardware_product_id) {
        if (not $c->db_hardware_products->active->search({ id => $input->{hardware_product_id} })->exists) {
            return $c->status(409, { error => 'Hardware product does not exist' });
        }
    }

    my $rack_size = $c->db_rack_roles->search(
        { 'racks.id' => $layout->rack_id },
        { join => 'racks' },
    )->get_column('rack_size')->single;

    # if changing rack location...
    if ($input->{rack_unit_start} and $input->{rack_unit_start} != $layout->rack_unit_start) {
        if ($c->db_rack_layouts->search({
                    rack_id => $layout->rack_id,
                    rack_unit_start => $input->{rack_unit_start},
                })->exists) {
            $c->log->debug('Conflict with rack_unit_start value of '.$input->{rack_unit_start});
            return $c->status(409, { error => 'rack_unit_start conflict' });
        }

        if ($input->{rack_unit_start} > $rack_size) {
            $c->log->debug("rack_unit_start $input->{rack_unit_start} starts beyond the end of the rack (size $rack_size)");
            return $c->status(409, { error => 'rack_unit_start beyond maximum' });
        }
    }

    # determine assigned slots, not counting the slots currently assigned to this layout (which
    # we will be giving up)

    my $current_rack_unit_size = $c->db_hardware_products
        ->search({ 'hardware_product.id' => $layout->hardware_product_id })
        ->get_column('rack_unit_size')->single;

    my $new_rack_unit_size = $input->{hardware_product_id}
        ? $c->db_hardware_products->search({ 'hardware_product.id' => $input->{hardware_product_id} })
            ->get_column('rack_unit_size')->single
        : $current_rack_unit_size;

    my $new_rack_unit_start = $input->{rack_unit_start} // $layout->rack_unit_start;

    if ($new_rack_unit_start + $new_rack_unit_size - 1 > $rack_size) {
        $c->log->debug('layout ends at rack unit '.($new_rack_unit_start + $new_rack_unit_size - 1)
            .", beyond the end of the rack (size $rack_size)");
        return $c->status(409, { error => 'rack_unit_start+rack_unit_size beyond maximum' });
    }

    my %assigned_rack_units = map +($_ => 1), $layout->related_resultset('rack')->assigned_rack_units;

    delete @assigned_rack_units{$layout->rack_unit_start .. ($layout->rack_unit_start + $current_rack_unit_size - 1) };

    my @desired_slots = $new_rack_unit_start .. ($new_rack_unit_start + $new_rack_unit_size - 1);

    if (any { $assigned_rack_units{$_} } @desired_slots) {
        $c->log->debug('Rack unit slot '.$input->{rack_unit_start}.' is already assigned');
        return $c->status(409, { error => 'rack_unit_start conflict' });
    }

    $c->res->headers->location('/layout/'.$layout->id);

    $layout->set_columns($input);
    return $c->status(204) if not $layout->is_changed;

    $layout->update({ updated => \'now()' });
    return $c->status(303);
}

=head2 delete

Deletes the specified rack layout.

=cut

sub delete ($c) {
    if (my $device_id = $c->stash('rack_layout_rs')->related_resultset('device_location')->get_column('device_id')->single) {
        $c->log->debug('Cannot delete layout: occupied by device id '.$device_id);
        return $c->status(409, { error => 'cannot delete a layout with a device occupying it' });
    }

    $c->stash('rack_layout_rs')->delete;
    $c->log->debug('Deleted rack layout '.$c->stash('layout_id_or_rack_unit_start')
        .($c->stash('rack_id') ? ' in rack id '.$c->stash('rack_id') : ''));
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
