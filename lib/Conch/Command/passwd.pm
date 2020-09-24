package Conch::Command::passwd;

=pod

=head1 NAME

passwd - change a user's password

=head1 SYNOPSIS

  bin/conch passwd [--id <user_id>] [--email <email>] [--password <password>]

  --id        The user's id.
  --email     The user's email address. required, if id is not provided.
  --password  The user's new password. If not provided, one will be randomly generated and echoed.

  --help      print usage message and exit

=cut

use Mojo::Base 'Mojolicious::Command', -signatures;
use Getopt::Long::Descriptive;

has description => 'Change a user\'s password';

has usage => sub { shift->extract_usage };  # extracts from SYNOPSIS

sub run ($self, @opts) {
  local @ARGV = @opts;
  my ($opt, $usage) = describe_options(
    # the descriptions aren't actually used anymore (mojo uses the synopsis instead)... but
    # the 'usage' text block can be accessed with $opt->usage
    'passwd %o',
    [ 'id|i=s',       'the user\'s id' ],
    [ 'email|e=s',    'the user\'s email address' ],
    [ 'password|p=s', 'the user password' ],
    [],
    [ 'help',         'print usage message and exit', { shortcircuit => 1 } ],
  );

  die 'must provide either id or email' if not $opt->id and not $opt->email;

  my $user_rs = $self->app->db_user_accounts;
  my $user = $opt->id ? $user_rs->find($opt->id)
    : $user_rs->find_by_email($opt->email);

  my $echo_password = !$opt->password;
  my $new_password = $opt->password // $self->app->random_string;

  $user->update({
    password => $new_password,
    refuse_session_auth => 1,
    force_password_change => 0,
  });

  say 'updated password for user ', $user->name,
    ' with email ', $user->email, ' (user id ', $user->id, ').',
    ($echo_password ? " new password: $new_password" : '');
}

1;
__END__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<http://mozilla.org/MPL/2.0/>.

=cut
# vim: set sts=2 sw=2 et :
