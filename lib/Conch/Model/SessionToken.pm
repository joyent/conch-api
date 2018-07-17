=pod

=head1 NAME

Conch::Model::SessionToken

=head1 METHODS

=cut

package Conch::Model::SessionToken;
use Mojo::Base -base, -signatures;

use Conch::UUID qw(is_uuid);
use Session::Token;

has [
	qw(
		email
		id
		name
		password_hash
		)
];

=head2 create

Create and record a session token

=cut

sub create ( $class, $user_id, $expires ) {
	my $token = Session::Token->new->get;

	Conch::Pg->new->db->query(
		q{
			insert into user_session_token
				(user_id, token_hash, expires)
			values( ?, digest(?, 'sha256'), to_timestamp(?)::timestamptz)
		},
		$user_id,
		$token,
		$expires,
	);
	return $token;
}

=head2 check_token

Check if a session token is valid for the user ID. Returns 1 if valid, 0 otherwise

=cut

sub check_token ( $class, $user_id, $token ) {

	Conch::Pg->new->db->delete( 'user_session_token',
		{ expires => { '<=' => 'now()' } } );

	return Conch::Pg->new->db->query(
		q{
			select 1
			from user_session_token
			where
				user_id = ? and
				token_hash = digest(?, 'sha256')
		},
		$user_id,
		$token
	)->rows;
}

=head2 use_token

Use a token by permanetly deleting it from the database. Will return 1 if the
token was present and valid, 0 otherwise.

=cut

sub use_token ( $class, $user_id, $token ) {

	Conch::Pg->new->db->delete( 'user_session_token',
		{ expires => { '<=' => 'now()' } } );

	return Conch::Pg->new->db->query(
		q{
			delete from user_session_token
			where
				user_id = ? and
				token_hash = digest(?, 'sha256')
		},
		$user_id,
		$token
	)->rows;
}

=head2 revoke_user_tokens

Revoke all user session tokens by permanently deleting the from the database

=cut

sub revoke_user_tokens ( $class, $user_id ) {
	Conch::Pg->new->db->delete( 'user_session_token', { user_id => $user_id } )
		->rows;
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
