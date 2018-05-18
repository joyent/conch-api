=pod

=head1 NAME

Conch::Controller::WorkspaceDevice

=head1 METHODS

=cut

package Conch::Controller::WorkspaceDevice;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Conch::Models;

=head2 list

Get a list of all devices in the current stashed C<current_workspace>

=cut

sub list ($c) {
	my $workspace_devices = Conch::Model::WorkspaceDevice->new->list(
		$c->stash('current_workspace')->id,

		# If 'active' query parameter specified, filter devices seen within in
		# 300 seconds (5 minutes)
		defined( $c->param('active') ) ? 300 : undef
	);

	my @devices = @$workspace_devices;
	@devices = grep { defined( $_->graduated ); } @devices
		if ( defined( $c->param('graduated') )
		and uc( $c->param('graduated') ) eq 'T' );

	@devices = grep { !defined( $_->graduated ) } @devices
		if ( defined( $c->param('graduated') )
		and uc( $c->param('graduated') ) eq 'F' );

	@devices = grep { uc( $_->health ) eq uc( $c->param('health') ) } @devices
		if defined( $c->param('health') );

	# transform result from hashes to single string field, should be added last
	if ( defined $c->param('ids_only') ) {
		@devices = map { $_->id } @devices;
	}

	$c->status( 200, \@devices );
}

1;

__DATA__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License, 
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.

=cut

