=head1 Conch::Log

Enhanced Mojo logger that logs with file path, and caller data using the Bunyan
log format

See also: Mojo::Log, Mojo::Log::More, and node-bunyan

=head1 SYNOPSIS

    $app->log(Conch::Log->new)

=head1 METHODS

=head2 debug

=head2 info

=head2 warn

=head2 error

=head2 fatal

=head2 raw

See L<Conch::Plugin::Logger> for a use case of C<raw>

=cut

package Conch::Log;

use Mojo::Base 'Mojo::Log';
use Mojo::JSON;
use File::Spec;
use Sys::Hostname;
use Conch::Time;

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    $self->unsubscribe('message');
    $self->on(message => '_message');
    return $self;
}

has 'request_id';
has 'payload';
has 'name' => 'conch-api';


sub _message {
    my $self = shift;
    my ($level, $msg) = @_;

    return unless $self->is_level($level);

    if ($self->payload) {
        $self->append(Mojo::JSON::to_json($self->payload)."\n");
        return;
    }

    my @caller = caller(3);

    my ($package, $filepath, $line, $filename);

    if (scalar @caller) {
        ($package, $filepath, $line) = ($caller[0], $caller[1], $caller[2]);
        $filename = (File::Spec->splitpath($filepath))[2];
    }
    else {
        ($package, $line, $filename) = ('unknown', 0, 'unknown');
    }

    my $log = {
        v        => 1,
        pid      => $$,
        hostname => hostname,
        time     => Conch::Time->now->iso8601,
        level    => $level,
        msg      => $msg,
        name     => $self->name,
        req_id   => $self->request_id,
        src      => {
            func => $package,
            file => $filename,
            line => $line,
        },
    };

    $self->append(Mojo::JSON::to_json($log)."\n");
}

1;
__END__

=pod

=head1 LICENSING

Based on Mojo::Log::More : https://metacpan.org/pod/Mojo::Log::More

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.

=cut
# vim: set ts=4 sts=4 sw=4 et :
