=pod

=head1 NAME

Conch::Route::Workspace

=head1 METHODS

=cut

package Conch::Route::Workspace;
use Mojo::Base -strict;

use Exporter 'import';
our @EXPORT_OK = qw(
	workspace_routes
);


=head2 workspace_routes

Sets up the routes for /workspace

=cut

sub workspace_routes {
	my $r = shift;

	$r->get('/workspace')->to('workspace#list');
	$r->get('/workspace/:id')->to('workspace#get');

	# routes namespaced under a specific workspace
	my $in_workspace = $r->under('/workspace/:id')->to('workspace#under');

	$in_workspace->get('/child')->to('workspace#get_sub_workspaces');
	$in_workspace->post('/child')->to('workspace#create_sub_workspace');

	$in_workspace->get('/device')->to('workspace_device#list');

# Redirect /workspace/:id/device/active to use query parameter on /workspace/:id/device
	$in_workspace->get(
		'/device/active',
		sub {
			my $c    = shift;
			my @here = @{ $c->url_for->path->parts };
			pop @here;
			$c->redirect_to(
				$c->url_for( join( '/', @here ) )->query( active => 't' )->to_abs );
		}
	);

	$in_workspace->get('/problem')->to('workspace_problem#list');

	$in_workspace->get('/rack')->to('workspace_rack#list');
	$in_workspace->post('/rack')->to('workspace_rack#add');

	my $with_workspace_rack =
		$in_workspace->under('/rack/:rack_id')->to('workspace_rack#under');

	$with_workspace_rack->get('')->to('workspace_rack#get_layout');
	$with_workspace_rack->delete('')->to('workspace_rack#remove');
	$with_workspace_rack->post('/layout')->to('workspace_rack#assign_layout');

	$in_workspace->get('/room')->to('workspace_room#list');
	$in_workspace->put('/room')->to('workspace_room#replace_rooms');

	$in_workspace->get('/relay')->to('workspace_relay#list');

	$in_workspace->get('/user')->to('workspace_user#list');
	$in_workspace->post('/user')->to('workspace_user#invite');

	$in_workspace->get('/validation_state')->to('workspace_validation#workspace_validation_states');
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
