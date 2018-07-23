=pod

=head1 NAME

Conch::Controller::User

=head1 METHODS

=cut

package Conch::Controller::User;

use Mojo::Base 'Mojolicious::Controller', -signatures;
use Mojo::Exception;

use Conch::Model::User;
use Conch::Model::SessionToken;
use Conch::UUID qw( is_uuid );

=head2 revoke_own_tokens

Revoke the user's own session tokens.
B<NOTE>: This will cause the next request to fail authentication.

=cut

sub revoke_own_tokens ($c) {
	Conch::Model::SessionToken->revoke_user_tokens( $c->stash('user_id' ) );
	$c->status(204);
}

=head2 revoke_user_tokens

Revoke a specified user's session tokens. Global admin only.

=cut

sub revoke_user_tokens ($c) {
	return $c->status( 403, { error => 'Must be global admin' } )
		unless $c->is_global_admin;

	my $user_param = $c->param('id');
	my $user;
	if ( is_uuid($user_param) ) {
		$user = Conch::Model::User->lookup($user_param);
	}
	elsif ( $user_param =~ s/^email\=// ) {
		$user = Conch::Model::User->lookup_by_email($user_param);
	}
	return $c->status( 404, { error => "user $user_param not found" } )
		unless $user;

	Conch::Model::SessionToken->revoke_user_tokens( $user->id );

	$c->status(204);
}

=head2 set_settings

Override the settings for a user with the provided payload

=cut

sub set_settings ($c) {
	my $body = $c->req->json;
	return $c->status( 400, { error => 'Payload required' } ) unless $body;

	my $user = Conch::Model::User->lookup( $c->stash('user_id') );
	Mojo::Exception->throw('Could not find previously stashed user')
		unless $user;

	$user->set_settings($body);

	$c->status(200);
}

=head2 set_setting

Set the value of a single setting for the user

=cut

sub set_setting ($c) {
	my $body  = $c->req->json;
	my $key   = $c->param('key');
	my $value = $body->{$key};
	return $c->status(
		400,
		{
			error =>
				"Setting key in request object must match name in the URL ('$key')"
		}
	) unless $value;

	my $user = Conch::Model::User->lookup( $c->stash('user_id') );
	Mojo::Exception->throw('Could not find previously stashed user')
		unless $user;

	my $ret = $user->set_setting( $key => $value );
	if ($ret) {
		return $c->status(200);
	}
	else {
		return $c->status( 500, "Failed to set setting" );
	}
}

=head2 get_settings

Get the key/values of every setting for a User

=cut

sub get_settings ($c) {
	my $user = Conch::Model::User->lookup( $c->stash('user_id') );
	Mojo::Exception->throw('Could not find previously stashed user')
		unless $user;

	my $settings = $user->settings();
	my %output;
	for my $k ( keys $settings->%* ) {
		$output{$k} = $settings->{$k};
	}

	$c->status( 200, \%output );
}

=head2 get_setting

Get the individual key/value pair for a setting for the User

=cut

sub get_setting ($c) {
	my $key = $c->param('key');

	my $user = Conch::Model::User->lookup( $c->stash('user_id') );
	Mojo::Exception->throw('Could not find previously stashed user')
		unless $user;

	my $settings = $user->settings;

	return $c->status( 404, { error => "No such setting '$key'" } )
		unless $settings->{$key};

	$c->status( 200, { $key => $settings->{$key} } );
}

=head2 delete_setting

Delete a single setting for a user, provided it was set previously

=cut

sub delete_setting ($c) {
	my $key = $c->param('key');

	my $user = Conch::Model::User->lookup( $c->stash('user_id') );
	Mojo::Exception->throw('Could not find previously stashed user')
		unless $user;

	my $settings = $user->settings;

	return $c->status( 404, { error => "No such setting '$key'" } )
		unless $settings->{$key};

	if ( $user->delete_setting($key) ) {
		return $c->status(204);
	}
	else {
		return $c->status( 500 => "Failed to delete setting" );
	}
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
