=pod

=head1 NAME

Conch::Mail

=head1 METHODS

=cut

package Conch::Mail;

use strict;
use warnings;

use Mail::Sendmail;
use Data::Printer;
use Log::Any '$log';

use Exporter 'import';
our @EXPORT = qw(
	new_user_invite password_reset_email
);

=head2 new_user_invite

Template for the email for inviting a new user

=cut

sub new_user_invite {
	my ($args)   = @_;
	my $email    = $args->{email};
	my $password = $args->{password};

	my %mail = (
		To      => $email,
		From    => 'noreply@conch.joyent.us',
		Subject => "Welcome to Conch!",
		Message => qq{Hello,

    You have been invited to join Joyent Conch. An account has been created for
    you. Please log into https://conch.joyent.us using the credentials
    below:

    Username: $email
    Password: $password

    Thank you,
    Joyent Build Ops Team
    }

	);
	if ( sendmail %mail ) {
		$log->info("New user invite successfully sent to $email.");
	}
	else {
		$log->error("Sendmail error: $Mail::Sendmail::error");
	}
}



=head2 password_reset_email

Template for reseting a existing user's password

=cut

sub password_reset_email {
	my ($args)   = @_;
	my $email    = $args->{email};
	my $password = $args->{password};

	my %mail = (
		To      => $email,
		From    => 'noreply@conch.joyent.us',
		Subject => "Conch Password Reset",
		Message => qq{Hello,

    A request was received to reset your password.  A new password has been
    randomly generated and your old password has been deactivated.

    Please log into https://conch.joyent.us using the following credentials:

    Username: $email
    Password: $password


    Thank you,
    Joyent Build Ops Team
    }

	);
	if ( sendmail %mail ) {
		$log->info("Existing user invite successfully sent to $email.");
	}
	else {
		$log->error("Sendmail error: $Mail::Sendmail::error");
	}
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

