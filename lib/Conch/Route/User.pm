=pod

=head1 NAME

Conch::Route::User

=head1 METHODS

=cut

package Conch::Route::User;
use Mojo::Base -strict;

use Exporter 'import';
our @EXPORT_OK = qw( user_routes);

use DDP;

=head2 user_routes

Sets up routes for the /user namespace

=cut

sub user_routes {
	my $r = shift;	# secured, under /user

	$r->post('/me/revoke')->to('user#revoke_own_tokens');
	$r->post('/#id/revoke')->to('user#revoke_user_tokens');

	$r->get('/me/settings')->to('user#get_settings');
	$r->post('/me/settings')->to('user#set_settings');

	$r->get('/me/settings/#key')->to('user#get_setting');
	$r->post('/me/settings/#key')->to('user#set_setting');
	$r->delete('/me/settings/#key')->to('user#delete_setting');

	# after changing password, (possibly) pass through to logging out too
	$r->post('/me/password')->to('user#change_password')
		->under->any->to('login#session_logout');
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
