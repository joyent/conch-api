package Conch::Mail;

use strict;
use warnings;

use Mail::Sendmail;
use Data::Printer;
use Log::Any '$log';

use Exporter 'import';
our @EXPORT = qw(
  new_user_invite existing_user_invite 
);

sub new_user_invite {
  my ($args)   = @_;
  my $username = $args->{name};
  my $email    = $args->{email};
  my $password = $args->{password};

  my %mail = (
    To      => $email,
    From    => 'noreply@preflight.scloud.zone',
    Subject => "Welcome to Conch!",
    Message => qq{Hello,

    You have been invited to join Joyent Conch. An account has been created for
    you. Please log into https://preflight.scloud.zone using the credentials
    below:

    Username: $username
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
  my $username       = $args->{name};
  my $email          = $args->{email};
  my $workspace_name = $args->{workspace_name};

  my %mail = (
    To      => $email,
    From    => 'noreply@preflight.scloud.zone',
    Subject => "Invitation to join new Conch workspace",
    Message => qq{Hello,

    You have been invited to join a new Joyent Conch workspace
    "$workspace_name".  Please log into https://preflight.scloud.zone using
    your existing account credentails with username '$username'. You can switch
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

1;
