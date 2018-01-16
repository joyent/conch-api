package Conch::Mail;

use strict;
use warnings;

use Mail::Sendmail;
use Data::Printer;
use Log::Any '$log';

use Exporter 'import';
our @EXPORT = qw(
  new_user_invite existing_user_invite password_reset_email
);

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

sub existing_user_invite {
  my ($args)         = @_;
  my $email          = $args->{email};
  my $workspace_name = $args->{workspace_name};

  my %mail = (
    To      => $email,
    From    => 'noreply@conch.joyent.us',
    Subject => "Invitation to join new Conch workspace",
    Message => qq{Hello,

    You have been invited to join a new Joyent Conch workspace
    "$workspace_name".  Please log into https://conch.joyent.us using
    your existing account credentails with username '$email'. You can switch
    between available workspaces in the sidebar.

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
