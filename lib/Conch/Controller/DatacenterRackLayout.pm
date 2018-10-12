=pod

=head1 NAME

Conch::Controller::DatacenterRackLayout

=head1 METHODS

=cut

package Conch::Controller::DatacenterRackLayout;

use Role::Tiny::With;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use Conch::UUID 'is_uuid';

use Conch::Models;

with 'Conch::Role::MojoLog';


=head2 find_datacenter_rack_layout

Supports rack layout lookups by id

=cut

sub find_datacenter_rack_layout ($c) {
	unless($c->is_system_admin) {
		return $c->status(403);
	}

	my $layout = $c->db_datacenter_rack_layouts->find($c->stash('layout_id'));
	if (not $layout) {
		$c->log->debug("Could not find datacenter rack layout ".$c->stash('layout_id'));
		return $c->status(404 => { error => "Not found" });
	}

	$c->log->debug("Found datacenter rack layout ".$layout->id);
	$c->stash('rack_layout' => $layout);
	return 1;
}

=head2 create

=cut

sub create ($c) {
	return $c->status(403) unless $c->is_system_admin;
	my $input = $c->validate_input('RackLayoutCreate');
	return if not $input;

	unless ($c->db_datacenter_racks->search({ id => $input->{rack_id} })->count) {
		$c->log->debug("Could not find datacenter rack ".$input->{rack_id});
		return $c->status(400 => { "error" => "Rack does not exist" });
	}

	unless(Conch::Model::HardwareProduct->lookup($input->{product_id})) {
		$c->log->debug("Could not find hardware product ".$input->{product_id});
		return $c->status(400 => { "error" => "Hardware product does not exist" });
	}

	if ($c->db_datacenter_rack_layouts->search(
				{ rack_id => $input->{rack_id}, rack_unit_start => $input->{ru_start} },
			)->count) {
		$c->log->debug('Conflict with ru_start value of '.$input->{ru_start});
		return $c->status(400 => { error => 'ru_start conflict' });
	}

	$input->{hardware_product_id} = delete $input->{product_id};
	$input->{rack_unit_start} = delete $input->{ru_start};

	my $layout = $c->db_datacenter_rack_layouts->create($input);
	$c->log->debug('Created datacenter rack layout '.$layout->id);

	$c->status(303 => '/layout/'.$layout->id);
}

=head2 get

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

	my @layouts = $c->db_datacenter_rack_layouts->all;
	$c->log->debug("Found ".scalar(@layouts)." datacenter rack layouts");
	$c->status(200 => \@layouts);
}

=head2 update

=cut

sub update ($c) {
	my $input = $c->validate_input('RackLayoutUpdate');
	return if not $input;

	if ($input->{rack_id}) {
		unless ($c->db_datacenter_racks->search({ id => $input->{rack_id} })->count) {
			return $c->status(400 => { "error" => "Rack does not exist" });
		}
	}

	if ($input->{product_id}) {
		unless(Conch::Model::HardwareProduct->lookup($input->{product_id})) {
			return $c->status(400 => { "error" => "Hardware product does not exist" });
		}
	}

	if ($input->{ru_start} && ($input->{ru_start} != $c->stash('rack_layout')->rack_unit_start)) {
		if ($c->db_datacenter_rack_layouts->search(
					{ rack_id => $c->stash('rack_layout')->rack_id, rack_unit_start => $input->{ru_start} }
				)->count) {
			$c->log->debug('Conflict with ru_start value of '.$input->{ru_start});
			return $c->status(400 => { error => 'ru_start conflict' });
		}
	}

	$input->{hardware_product_id} = delete $input->{product_id} if exists $input->{product_id};
	$input->{rack_unit_start} = delete $input->{ru_start} if exists $input->{ru_start};

	$c->stash('rack_layout')->update({ %$input, updated => \'NOW()' });

	return $c->status(303 => "/layout/".$c->stash('rack_layout')->id);
}


=head2 delete


=cut

sub delete ($c) {
	$c->stash('rack_layout')->delete;
	$c->log->debug("Deleted datacenter rack layout ".$c->stash('rack_layout')->id);
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
