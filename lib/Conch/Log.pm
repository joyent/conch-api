package Conch::Log;

use v5.26;
use Mojo::Base 'Mojo::Log', -signatures;

use Sys::Hostname;
use Mojo::JSON 'to_json';
use Mojo::Path;
use Mojo::Home;
use Conch::Time;

=head1 Conch::Log

Enhanced Mojo logger with formatters to log in
L<Bunyan|https://github.com/trentm/node-bunyan> format, optionally with stack traces.

=head1 SYNOPSIS

    $app->log(Conch::Log->new(bunyan => 1));

    $app->log->debug('a message');

    local $Conch::Log::REQUEST_ID = 'deadbeef';
    $log->info({ raw_data => [1,2,3] });

=head1 ATTRIBUTES

L<Conch::Log> inherits all attributes from L<Mojo::Log> and implements the
following new ones:

=head2 bunyan

A boolean option (defaulting to false): log in bunyan format. If passed a string or list of
strings, these are added as the C<msg> field in the logged data; otherwise, the passed-in data
will be included as-is.

C<$Conch::Log::REQUEST_ID> is included in the data, when defined (make sure to localize this to
the scope of your request or asynchronous subroutine).

=head2 with_trace

A boolean option (defaulting to false): include stack trace information. Must be combined with
C<< bunyan => 1 >>.

=cut

has bunyan => 0;
has with_trace => 0;

our $REQUEST_ID;

=head1 METHODS

L<Conch::Log> inherits all methods from L<Mojo::Log>.

=cut

sub format {
    my $self = shift;
    return $self->next::method(@_) if @_;

    $self->bunyan
  ? ($self->with_trace ? \&_format_bunyan_with_trace : \&_format_bunyan)
  : $self->next::method(@_);
}

sub _bunyan_data ($time, $level, @msg) {
    +{
        name => 'conch-api',
        hostname => state $hostname = Sys::Hostname::hostname,
        v => 2, # current bunyan version
        pid => $$,
        level => $level,
        time => Conch::Time->from_epoch($time)->iso8601,
        defined $REQUEST_ID ? ( req_id => $REQUEST_ID ) : (),
        @msg > 1 || !ref($msg[0]) ? (msg => join("\n", @msg)) : $msg[0]->%*,
    };
}

sub _format_bunyan ($time, $level, @msg) {
    # Mojo::Log::append encodes into UTF-8, so we do not do it here.
    to_json(_bunyan_data(@_))."\n";
}

sub _format_bunyan_with_trace ($time, $level, @msg) {
    # go back 5 frames, past:
    # Conch::Log::_format_bunyan_with_trace
    # Conch::Log::_message
    # Mojo::Emitter::emit
    # Mojo::Log::_log
    # Mojo::Log::$level
    use constant FRAMES => 4;
    my ($file, $line) = (caller(FRAMES))[1,2];
    to_json(+{
        _bunyan_data(@_)->%*,
        src => {
            file => $file ? Mojo::File::path($file)->to_rel(Mojo::Home->new)->to_string : 'unknown',
            line => $line // 0,
            func => (caller(FRAMES+1))[3] // 'unknown',
        },
    })."\n";
}

1;
__END__

=pod

=head1 SEE ALSO

L<node-bunyan|https://github.com/trentm/node-bunyan/>

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<http://mozilla.org/MPL/2.0/>.

=cut
# vim: set ts=4 sts=4 sw=4 et :
