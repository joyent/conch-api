=pod

=head1 NAME

Conch::Route::Validation

=head1 METHODS

=cut

package Conch::Route::Validation;
use Mojo::Base -strict;

use Exporter 'import';
our @EXPORT_OK = qw( validation_routes );

use DDP;

=head2 validation_routes

Sets up routes for /validation and /validation_plan routes

=cut

sub validation_routes {
	my $r = shift;

	$r->get('/validation')->to('validation#list');

	$r->post('/validation_plan')->to('validation_plan#create');
	$r->get('/validation_plan')->to('validation_plan#list');
	$r->get('/validation_plan/#id')->to('validation_plan#get');
	my $with_plan =
		$r->under('/validation_plan/#id')->to('validation_plan#under');
	$with_plan->get('/validation')->to('validation_plan#list_validations');
	$with_plan->post('/validation')->to('validation_plan#add_validation');
	$with_plan->get('/validation/#validation_id')
		->to('validation_plan#get_validation');
	$with_plan->delete('/validation/#validation_id')
		->to('validation_plan#remove_validation');
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
