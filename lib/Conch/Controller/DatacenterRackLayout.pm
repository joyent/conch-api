=pod

=head1 NAME

Conch::Controller::DatacenterRackLayout

=head1 METHODS

=cut

package Conch::Controller::DatacenterRackLayout;

use Mojo::Base 'Mojolicious::Controller', -signatures;
use Conch::UUID 'is_uuid';

use Conch::Models;
use List::MoreUtils qw(firstval);


=head2 under

Supports rack layout lookups by id

=cut

sub under ($c) {
	unless($c->is_global_admin) {
		$c->status(403);
		return undef;
	}

	my $r = Conch::Model::DatacenterRackLayout->from_id($c->param('id'));

	if ($r) {
		$c->stash('rack_layout' => $r);
		return 1;
	} else {
		$c->status(404 => { error => "Not found" });
		return undef;
	}
}

=head2 create

=cut

sub create ($c) {
	return $c->status(403) unless $c->is_global_admin;
	my $d = $c->validate_input('RackLayoutCreate');
	return if not $d;

	unless(Conch::Model::DatacenterRack->from_id($d->{rack_id})) {
		return $c->status(400 => { "error" => "Rack does not exist" });
	}

	unless(Conch::Model::HardwareProduct->lookup($d->{product_id})) {
		return $c->status(400 => { "error" => "Hardware product does not exist" });
	}

	my @r = Conch::Model::DatacenterRackLayout->from_rack_id($d->{rack_id})->@*;
	my $v = firstval { $_->{ru_start} == $d->{ru_start} } @r;
	if($v) {
		return $c->status(400 => {
			error => "ru_start conflict"
		});
	}

	my $r = Conch::Model::DatacenterRackLayout->new($d->%*)->save();

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
	$c->status(200, Conch::Model::DatacenterRackLayout->all());
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
