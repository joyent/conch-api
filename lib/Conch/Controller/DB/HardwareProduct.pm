package Conch::Controller::DB::HardwareProduct;

use Role::Tiny::With;
use Mojo::Base 'Mojolicious::Controller', -signatures;

with 'Conch::Role::MojoLog';

=head2 find_hardware_product

Handles looking up the object by id or sku depending on the url pattern

=cut

sub find_hardware_product ($c) {
	my $h;

	if($c->stash('hardware_product_id') =~ /^(.+?)\=(.+)$/) {
		my $k = $1;
		my $v = $2;

		$c->log->debug("Looking up a HardwareProduct by identifier ($k = $v)");

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
			$c->log->debug("Unknown identifier '$k' passed to HardwareProduct lookup");
			$c->status('501');
			return undef;
		}
	} else {
		$c->log->debug("Looking up a HardwareProduct by id ".$c->stash('hardware_product_id'));
		$h = $c->schema->resultset("HardwareProduct")->single({
			id => $c->stash('hardware_product_id'),
			deactivated => undef,
		});
	}

	if ($h) {
		$c->log->debug("Found hardware product ".$h->id);
		$c->stash('hardware_product' => $h);
		return 1;
	} else {
		$c->log->debug("Could not locate a valid hardware product");
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
	$c->log->debug("Found ".(scalar @r)." hardware products");
	return $c->status(200, \@r);
}


=head2 get_one

=cut

sub get_one ($c) {
	$c->status(200 => $c->stash('hardware_product'));
}


=head2 create

=cut

sub create ($c) {
	return $c->status(403) unless $c->is_global_admin;
	my $i = $c->validate_input('DBHardwareProductCreate');
	if(not $i) {
		$c->log->warn("Input failed validation");
		return;
	}

	for my $k (qw[name alias sku]) {
		next unless $i->{$k};
		my @r = $c->schema->resultset("HardwareProduct")->search({
			$k => $i->{$k}
		})->all;
		if (scalar @r > 0) {
			$c->log->debug("Failed to create hardware product: unique constraint violation for $k");
			return $c->status(400 => {
				error => "Unique constraint violated on '$k'"
			});
		}
	}

	$i->{hardware_vendor_id} = delete $i->{vendor} if exists $i->{vendor};

	my $r = $c->schema->resultset("HardwareProduct")->create($i);

	$c->log->debug("Created hardware product ".$r->id);
	$c->status(303 => "/db/hardware_product/".$r->id);
}


=head2 update

=cut

sub update ($c) {
	return $c->status(403) unless $c->is_global_admin;

	my $i = $c->validate_input('DBHardwareProductUpdate');
	return if not $i;

	for my $k (qw[name alias sku]) {
		next unless $i->{$k};
		next if $i->{$k} eq $c->stash('hardware_product')->get_column($k);

		my @r = $c->schema->resultset("HardwareProduct")->search({
			$k => $i->{$k}
		})->all;

		if (scalar @r > 0) {
			$c->log->debug("Failed to create hardware product: unique constraint violation for $k");
			return $c->status(400 => {
				error => "Unique constraint violated on '$k'"
			});
		}
	}


	$c->stash('hardware_product')->update($i);
	$c->log->debug("Updated hardware product ".$c->stash('hardware_product')->id);
	$c->status(303 => "/db/hardware_product/".$c->stash('hardware_product')->id);
}


=head2 delete

=cut

sub delete ($c) {
	return $c->status(403) unless $c->is_global_admin;
	$c->stash('hardware_product')->update({ deactivated => 'NOW()' });
	$c->log->debug("Deleted hardware product ".$c->stash('hardware_product')->id);
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
