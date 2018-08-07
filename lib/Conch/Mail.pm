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

=head2 send_mail_with_template

Simple email sender.

=cut

sub send_mail_with_template {
	my ($content, $mail_args) = @_;

	# TODO: we should use Mojo::IOLoop->subprocess to send these.

	# TODO: make use of Mojo::Template for more sophisticated content munging.

	# TODO: rewrite from Mail::Sendmail to Email::Simple before rjbs kills us.
	if (not sendmail(%$mail_args, Message => $content)) {
		$log->error("Sendmail error: $Mail::Sendmail::error");
		return;
	}

	return 1;
}

=head2 new_user_invite

Template for the email for inviting a new user

=cut

sub new_user_invite {
	my ($args)   = @_;
	my $name     = $args->{name};
	my $email    = $args->{email};
	my $password = $args->{password};

	my $to = $email;
	$to = "$name <$to>" if $name ne $email;

	my $headers = {
		To      => $to,
		From    => 'noreply@conch.joyent.us',
		Subject => "Welcome to Conch!",
	};

	my $template = qq{Hello,

    You have been invited to join Joyent Conch. An account has been created for
    you. Please log into https://conch.joyent.us using the credentials
    below:

    Username: $name
    Email:    $email
    Password: $password

    Thank you,
    Joyent Build Ops Team
    };

	send_mail_with_template($template, $headers)
		&& $log->info("New user invite successfully sent to $email.");
}

=head2 changed_user_password

Send mail when resetting an existing user's password

=cut

sub changed_user_password {
	my ($args)   = @_;
	my $name     = $args->{name};
	my $email    = $args->{email};
	my $password = $args->{password};

	my $to = $email;
	$to = "$name <$to>" if $name ne $email;

	my $headers = {
		To      => $to,
		From    => 'noreply@conch.joyent.us',
		Subject => "Your Conch password has changed.",
	};
	my $template = qq{Hello,

    Your password at Joyent Conch has been reset. You should now log
    into https://conch.joyent.us using the credentials below.

	WARNING!!! You will only be able to use this password once, and
	must select a new password within 10 minutes after logging in.

    Username: $name
    Email:    $email
    Password: $password

    Thank you,
    Joyent Build Ops Team
    };

	send_mail_with_template($template, $headers)
		&& $log->info("Password reset email sent to $email.");
}

=head2 welcome_new_user

Template for the email when a new user has been created

=cut

sub welcome_new_user {
	my ($args)   = @_;
	my $name     = $args->{name};
	my $email    = $args->{email};
	my $password = $args->{password};

	my $to = $email;
	$to = "$name <$to>" if $name ne $email;

	my $headers = {
		To      => $to,
		From    => 'noreply@conch.joyent.us',
		Subject => "Welcome to Conch!",
	};

	my $template = qq{Hello,

    You have been invited to join Joyent Conch. An account has been created for
    you. Please log into https://conch.joyent.us using the credentials
    below:

    Username: $name
    Email:    $email
    Password: $password

    Thank you,
    Joyent Build Ops Team
    };

	send_mail_with_template($template, $headers)
		&& $log->info("New user invite successfully sent to $email.");
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
