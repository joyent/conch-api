package Conch::Controller::DB::HardwareProduct;

use Role::Tiny::With;
use Mojo::Base 'Mojolicious::Controller', -signatures;

with 'Conch::Role::MojoLog';

use List::Util 'none';
use Conch::UUID 'is_uuid';

=head2 find_hardware_product

Handles looking up the object by id or sku depending on the url pattern

=cut

sub find_hardware_product ($c) {
	my $hardware_product_rs = $c->db_hardware_products->active;

	my ($key, $value) = split(/=/, $c->stash('hardware_product_id'), 2);
	if ($key and $value) {
		if (none { $key eq $_ } qw(sku name alias)) {
			$c->log->debug("Unknown identifier '$key' passed to HardwareProduct lookup");
			return $c->status('501');
		}

		$c->log->debug("Looking up a HardwareProduct by identifier ($key = $value)");
		$hardware_product_rs = $hardware_product_rs->search({ $key => $value });
	} else {
		$c->log->debug("Looking up a HardwareProduct by id ".$c->stash('hardware_product_id'));
		return $c->status(404 => { error => 'Not found' }) if not is_uuid($c->stash('hardware_product_id'));
		$hardware_product_rs = $hardware_product_rs->search({ id => $c->stash('hardware_product_id') });
	}

	if (not $hardware_product_rs->exists) {
		$c->log->debug('Could not locate a valid hardware product');
		return $c->status(404 => { error => 'Not found' });
	}

	$c->stash('hardware_product_rs' => scalar $hardware_product_rs);
	return 1;
}


=head2 get_all

Response uses the DBHardwareProducts json schema.

=cut

sub get_all ($c) {
	my @hardware_products = $c->db_hardware_products->active->all;
	$c->log->debug('Found '.(scalar @hardware_products).' hardware products');
	return $c->status(200, \@hardware_products);
}


=head2 get_one

Response uses the DBHardwareProduct json schema.

=cut

sub get_one ($c) {
	$c->status(200 => $c->stash('hardware_product_rs')->single);
}


=head2 create

=cut

sub create ($c) {
	return $c->status(403) unless $c->is_system_admin;
	my $input = $c->validate_input('DBHardwareProductCreate');
	return if not $input;

	for my $key (qw[name alias sku]) {
		next unless $input->{$key};
		if ($c->db_hardware_products->search({ $key => $input->{$key} }) > 0) {
			$c->log->debug("Failed to create hardware product: unique constraint violation for $key");
			return $c->status(400 => {
				error => "Unique constraint violated on '$key'"
			});
		}
	}

	$input->{hardware_vendor_id} = delete $input->{vendor} if exists $input->{vendor};

	my $hardware_product = $c->db_hardware_products->create($input);

	$c->log->debug("Created hardware product ".$hardware_product->id);
	$c->status(303 => "/db/hardware_product/".$hardware_product->id);
}


=head2 update

=cut

sub update ($c) {
	return $c->status(403) unless $c->is_system_admin;

	my $input = $c->validate_input('DBHardwareProductUpdate');
	return if not $input;

	my $hardware_product = $c->stash('hardware_product_rs')->single;

	for my $key (qw[name alias sku]) {
		next unless defined $input->{$key};
		next if $input->{$key} eq $hardware_product->$key;

		if ($c->db_hardware_products->search({ $key => $input->{$key} }) > 0) {
			$c->log->debug("Failed to create hardware product: unique constraint violation for $key");
			return $c->status(400 => { error => "Unique constraint violated on '$key'" });
		}
	}

	$hardware_product->update({ %$input, updated => \'NOW()' });
	$c->log->debug('Updated hardware product '.$hardware_product->id);
	$c->status(303 => '/db/hardware_product/'.$hardware_product->id);
}


=head2 delete

=cut

sub delete ($c) {
	return $c->status(403) unless $c->is_system_admin;

	my $id = $c->stash('hardware_product_rs')->get_column('id')->single;
	$c->stash('hardware_product_rs')->deactivate;
	$c->log->debug("Deleted hardware product $id");
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
