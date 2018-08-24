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
use List::MoreUtils qw(firstval);

with 'Conch::Role::MojoLog';


=head2 find_datacenter_rack_layout

Supports rack layout lookups by id

=cut

sub find_datacenter_rack_layout ($c) {
	unless($c->is_global_admin) {
		$c->status(403);
		return undef;
	}

	my $r = Conch::Model::DatacenterRackLayout->from_id($c->stash('layout_id'));

	if ($r) {
		$c->log->debug("Found datacenter rack layout ".$r->id);
		$c->stash('rack_layout' => $r);
		return 1;
	} else {
		$c->log->debug("Could not find datacenter rack layout ".$c->stash('layout_id'));
		$c->status(404 => { error => "Not found" });
		return undef;
	}
}

=head2 create

=cut

sub create ($c) {
	return $c->status(403) unless $c->is_global_admin;
	my $d = $c->validate_input('RackLayoutCreate');
	if(not $d) {
		$c->log->debug("Input failed validation");
		return;
	}

	unless(Conch::Model::DatacenterRack->from_id($d->{rack_id})) {
		$c->log->debug("Could not find datacenter rack ".$d->{rack_id});
		return $c->status(400 => { "error" => "Rack does not exist" });
	}

	unless(Conch::Model::HardwareProduct->lookup($d->{product_id})) {
		$c->log->debug("Could not find hardware product ".$d->{product_id});
		return $c->status(400 => { "error" => "Hardware product does not exist" });
	}

	my @r = Conch::Model::DatacenterRackLayout->from_rack_id($d->{rack_id})->@*;
	my $v = firstval { $_->{ru_start} == $d->{ru_start} } @r;
	if($v) {
		$c->log->debug("Conflict with ru_start value of ".$d->{ru_start});
		return $c->status(400 => {
			error => "ru_start conflict"
		});
	}

	my $r = Conch::Model::DatacenterRackLayout->new($d->%*)->save();
	$c->log->debug("Created datacenter rack layout ".$r->id);

	$c->status(303 => "/layout/".$r->id);

}

=head2 get

=cut

sub get ($c) {
	$c->status(200, $c->stash('rack_layout'));
}



=head2 get_all


=cut

sub get_all ($c) {
	return $c->status(403) unless $c->is_global_admin;
	my $d = Conch::Model::DatacenterRackLayout->all();
	$c->log->debug("Found ".scalar($d->@*)." datacenter rack layouts");
	$c->status(200 => $d);
}

=head2 update

=cut

sub update ($c) {
	my $i = $c->validate_input('RackLayoutUpdate');
	return if not $i;

	if($i->{rack_id}) {
		unless(Conch::Model::DatacenterRack->from_id($i->{rack_id})) {
			return $c->status(400 => { "error" => "Rack does not exist" });
		}
	}

	if($i->{product_id}) {
		unless(Conch::Model::HardwareProduct->lookup($i->{product_id})) {
			return $c->status(400 => { "error" => "Hardware product does not exist" });
		}
	}

	if($i->{ru_start} && ($i->{ru_start} != $c->stash('rack_layout')->ru_start)) {
		my $v = firstval {
			$_->ru_start == $i->{ru_start}
		} Conch::Model::DatacenterRackLayout->from_rack_id(
			$c->stash('rack_layout')->rack_id
		)->@*;

		if($v) {
			$c->log->debug("Conflict with ru_start value of ".$i->{ru_start});
			return $c->status(400 => {
				error => "ru_start conflict"
			});
		}
	}

	$c->stash('rack_layout')->update($i->%*)->save();
	return $c->status(303 => "/layout/".$c->stash('rack_layout')->id);
}


=head2 delete


=cut

sub delete ($c) {
	$c->stash('rack_layout')->burn;
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
