package Conch::Controller::DB::HardwareProduct;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Conch::Models;

=head2 under

Handles looking up the object by id or sku depending on the url pattern 

=cut

sub under ($c) {
	my $h;

	if($c->param('id') =~ /^(.+?)\=(.+)$/) {
		my $k = $1;
		my $v = $2;
		if($k eq "sku") {
			$h = $c->schema->resultset("HardwareProduct")->single({
				sku => $v,
				deactivated => undef,
			});
		} elsif ($k eq "name") {
			$h = $c->schema->resultset("HardwareProduct")->single({
				name => $v,
				deactivated => undef,
			});
		} elsif ($k eq "alias") {
			$h = $c->schema->resultset("HardwareProduct")->single({
				alias => $v,
				deactivated => undef,
			});
		} else {
			$c->status('501');
			return undef;
		}
	} else {
		$h = $c->schema->resultset("HardwareProduct")->single({
			id => $c->param('id'),
			deactivated => undef,
		});
	}

	if ($h) {
		$c->stash('hardware_product' => $h);
		return 1;
	} else {
		$c->status(404 => { error => "Not found" });
		return undef;
	}

}


=head2 get_all

=cut

sub get_all ($c) {
	my @r = $c->schema->resultset("HardwareProduct")->search({
		deactivated => undef,
	})->all;
	return $c->status(200, \@r);
}


=head2 get_one

=cut

sub get_one ($c) {
	$c->status(200 => $c->stash('hardware_product')
	);
}


=head2 create

=cut

sub create ($c) {
	return $c->status(403) unless $c->is_global_admin;
	my $i = $c->validate_input('DBHardwareProductCreate') or return;

	for my $k (qw[name alias sku]) {
		next unless $i->{$k};
		my @r = $c->schema->resultset("HardwareProduct")->search({
			$k => $i->{$k}
		})->all;
		if (scalar @r > 0) {
			return $c->status(400 => {
				error => "Unique constraint violated on '$k'"
			});
		}
	}

	my $r = $c->schema->resultset("HardwareProduct")->create($i);
	$c->status(303 => "/db/hardware_product/".$r->id);
}


=head2 update

=cut

sub update ($c) {
	return $c->status(403) unless $c->is_global_admin;

	my $i = $c->validate_input('DBHardwareProductUpdate') or return;

	for my $k (qw[name alias sku]) {
		next unless $i->{$k};
		my @r = $c->schema->resultset("HardwareProduct")->search({
			$k => $i->{$k}
		})->all;
		if (scalar @r > 0) {
			return $c->status(400 => {
				error => "Unique constraint violated on '$k'"
			});
		}
	}


	$c->stash('hardware_product')->update($i);
	$c->status(303 => "/db/hardware_product/".$c->stash('hardware_product')->id);
}


=head2 delete

=cut

sub delete ($c) {
	return $c->status(403) unless $c->is_global_admin;
	$c->stash('hardware_product')->update({ deactivated => 'NOW()' });
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

