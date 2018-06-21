=pod

=head1 NAME

Conch::Plugin::Email

=head1 DESCRIPTION

Mojo plugin to wrap Conch::Mail

=head1 METHODS

=cut

package Conch::Plugin::Mail;
use Mojo::Base 'Mojolicious::Plugin', -signatures;

use Conch::Mail;

=head2 register

Adds a C<mail> mojo helper for itself

=cut

sub register ( $self, $app, $conf ) {
	$app->helper( mail => sub { $self } );
}


=head2 send_password_reset_email

Alias for Conch::Mail::password_reset_email

=cut

sub send_password_reset_email {
	shift;
	Conch::Mail::password_reset_email(@_);
}


=head2 send_new_user_invite

Alias for Conch::Mail::new_user_invite

=cut

sub send_new_user_invite {
	shift;
	Conch::Mail::new_user_invite(@_);
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

