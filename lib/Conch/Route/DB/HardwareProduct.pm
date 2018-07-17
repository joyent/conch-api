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

	my $d = $r->under('/hardware_product');
	$d->get('/')->to("DB::HardwareProduct#get_all");
	$d->post('/')->to("DB::HardwareProduct#create");

	my $i = $d->under('/:id')->to("DB::HardwareProduct#under");
	$i->get('/')->to("DB::HardwareProduct#get_one");
	$i->post('/')->to("DB::HardwareProduct#update");
	$i->delete('/')->to("DB::HardwareProduct#delete");
}

1;

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.

=cut
