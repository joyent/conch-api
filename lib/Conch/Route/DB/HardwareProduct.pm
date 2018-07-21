=head1 NAME

Conch::Route::DB::HardwareProduct

=head1 METHODS

=cut

package Conch::Route::DB::HardwareProduct;
use Mojo::Base -strict;

=head2 routes

Sets up the routes

=cut

sub routes {
	my ($class, $r) = @_;

	my $hardware_product = $r->any('/hardware_product');
	$hardware_product->get('/')->to("DB::HardwareProduct#get_all");
	$hardware_product->post('/')->to("DB::HardwareProduct#create");

	my $with_id = $hardware_product->under('/:id')->to("DB::HardwareProduct#under");
	$with_id->get('/')->to("DB::HardwareProduct#get_one");
	$with_id->post('/')->to("DB::HardwareProduct#update");
	$with_id->delete('/')->to("DB::HardwareProduct#delete");
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
