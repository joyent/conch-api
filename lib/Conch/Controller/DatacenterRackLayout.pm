package Conch::Controller::DatacenterRackLayout;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Role::Tiny::With;
with 'Conch::Role::MojoLog';

use List::Util 'any';

=pod

=head1 NAME

Conch::Controller::DatacenterRackLayout

=head1 METHODS

=head2 find_datacenter_rack_layout

Supports rack layout lookups by id

=cut

sub find_datacenter_rack_layout ($c) {
    unless($c->is_system_admin) {
        return $c->status(403);
    }

    my $layout = $c->db_datacenter_rack_layouts->find($c->stash('layout_id'));
    if (not $layout) {
        $c->log->debug('Could not find datacenter rack layout '.$c->stash('layout_id'));
        return $c->status(404 => { error => 'Not found' });
    }

    $c->log->debug('Found datacenter rack layout '.$layout->id);
    $c->stash('rack_layout' => $layout);
    return 1;
}

=head2 create

Creates a new datacenter_rack_layout entry according to the passed-in specification.

=cut

sub create ($c) {
    return $c->status(403) unless $c->is_system_admin;
    my $input = $c->validate_input('RackLayoutCreate');
    return if not $input;

    $input->{hardware_product_id} = delete $input->{product_id};
    $input->{rack_unit_start} = delete $input->{ru_start};

    unless ($c->db_datacenter_racks->search({ id => $input->{rack_id} })->exists) {
        $c->log->debug('Could not find datacenter rack '.$input->{rack_id});
        return $c->status(400 => { error => 'Rack does not exist' });
    }

    unless ($c->db_hardware_products->active->search({ id => $input->{hardware_product_id} })->exists) {
        $c->log->debug('Could not find hardware product '.$input->{hardware_product_id});
        return $c->status(400 => { error => 'Hardware product does not exist' });
    }

    my %occupied_rack_units = map { $_ => 1 }
        $c->db_datacenter_racks->search({ 'datacenter_rack.id' => $input->{rack_id} })
        ->occupied_rack_units;

    my $new_rack_unit_size = $c->db_hardware_products
        ->search({ 'hardware_product.id' => $input->{hardware_product_id} })
        ->related_resultset('hardware_product_profile')
        ->get_column('rack_unit')->single;

    my @desired_positions = $input->{rack_unit_start} .. ($input->{rack_unit_start} + $new_rack_unit_size - 1);

    if (any { $occupied_rack_units{$_} } @desired_positions) {
        $c->log->debug('Rack unit position '.$input->{rack_unit_start} . ' is already occupied');
        return $c->status(400 => { error => 'ru_start conflict' });
    }

    my $layout = $c->db_datacenter_rack_layouts->create($input);
    $c->log->debug('Created datacenter rack layout '.$layout->id);

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

    # TODO: to be more helpful to the UI, we should include the width of the hardware that will
    # occupy each rack_unit(s).

    my @layouts = $c->db_datacenter_rack_layouts
        #->search(undef, {
        #    join => { 'hardware_product' => 'hardware_product_profile' },
        #    '+columns' => { rack_unit_size =>  'hardware_product_profile.rack_unit' },
        #    collapse => 1,
        #})
        ->all;

    $c->log->debug('Found '.scalar(@layouts).' datacenter rack layouts');
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

    if ($input->{rack_id}) {
        unless ($c->db_datacenter_racks->search({ id => $input->{rack_id} })->exists) {
            return $c->status(400 => { error => 'Rack does not exist' });
        }
    }

    if ($input->{hardware_product_id}) {
        unless ($c->db_hardware_products->active->search({ id => $input->{hardware_product_id} })->exists) {
            return $c->status(400 => { error => 'Hardware product does not exist' });
        }
    }

    if ($input->{rack_unit_start} and $input->{rack_unit_start} != $c->stash('rack_layout')->rack_unit_start) {
        if ($c->db_datacenter_rack_layouts->search({
                    rack_id => $c->stash('rack_layout')->rack_id,
                    rack_unit_start => $input->{rack_unit_start},
                })->exists) {
            $c->log->debug('Conflict with ru_start value of '.$input->{rack_unit_start});
            return $c->status(400 => { error => 'ru_start conflict' });
        }
    }

    # determine occupied slots, not counting the slots currently occupied by this layout

    my %occupied_rack_units = map { $_ => 1 } $c->stash('rack_layout')
        ->related_resultset('datacenter_rack')->occupied_rack_units;

    my $current_rack_unit_size = $c->db_hardware_products->search(
        { 'hardware_product.id' => $c->stash('rack_layout')->hardware_product_id })
        ->related_resultset('hardware_product_profile')->get_column('rack_unit')->single;

    delete @occupied_rack_units{
        $c->stash('rack_layout')->rack_unit_start ..
        ($c->stash('rack_layout')->rack_unit_start + $current_rack_unit_size - 1)
    };

    my $new_rack_unit_size = $input->{hardware_product_id}
        ? $c->db_hardware_products->search({ 'hardware_product.id' => $input->{hardware_product_id} })
            ->related_resultset('hardware_product_profile')->get_column('rack_unit')->single
        : $current_rack_unit_size;

    my @desired_positions =
        ($input->{rack_unit_start} // $c->stash('rack_layout')->rack_unit_start)
        ..
        (($input->{rack_unit_start} // $c->stash('rack_layout')->rack_unit_start) + $new_rack_unit_size - 1);

    if (any { $occupied_rack_units{$_} } @desired_positions) {
        $c->log->debug('Rack unit position '.$input->{rack_unit_start} . ' is already occupied');
        return $c->status(400 => { error => 'ru_start conflict' });
    }

    $c->stash('rack_layout')->update({ %$input, updated => \'now()' });

    return $c->status(303 => '/layout/'.$c->stash('rack_layout')->id);
}

=head2 delete

Deletes the specified rack layout.

=cut

sub delete ($c) {
    $c->stash('rack_layout')->delete;
    $c->log->debug('Deleted datacenter rack layout '.$c->stash('rack_layout')->id);
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
