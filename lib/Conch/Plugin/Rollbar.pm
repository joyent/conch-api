package Conch::Plugin::Rollbar;

use Mojo::Base 'Mojolicious::Plugin', -signatures;
use Sys::Hostname ();
use Conch::UUID 'create_uuid_str';

use constant ROLLBAR_ENDPOINT => 'https://api.rollbar.com/api/1/item/';

=pod

=head1 NAME

Conch::Plugin::Rollbar

=head1 DESCRIPTION

Mojo plugin to send exceptions to L<Rollbar|https://rollbar.com>

=head1 HELPERS

=cut

sub register ($self, $app, $config) {

=head2 send_exception_to_rollbar

Asynchronously send exception details to Rollbar if 'rollbar_access_token' is
configured. Returns a unique uuid suitable for logging, to correlate with the
Rollbar entry thus created.

=cut

    $app->helper(send_exception_to_rollbar => \&_record_exception);

    $app->hook(
        before_render => sub ($c, $args) {
            my $template = $args->{template};

            if (my $exception = $c->stash('exception')
                    or ($template and $template =~ /exception/)) {
                $exception //= $args->{exception};
                $exception->verbose(1);
                my $rollbar_id = $c->send_exception_to_rollbar($exception);
                $c->log->debug('exception sent to rollbar: id '.$rollbar_id);
            }
        }
    );
}


sub _record_exception ($c, $exception, @) {
    my $access_token = $c->app->config('rollbar_access_token');
    if (not $access_token) {
        $c->log->warn('Unable to send exception to Rollbar - no access token configured');
        return;
    }

    my @frames = map +{
        class_name => $_->[0],
        filename   => $_->[1],
        lineno     => $_->[2],
        method     => $_->[3],
    },
    $exception->frames->@*;

    # we only have context for the first frame.
    # Mojo::Exception data contains line numbers as well.
    $frames[0]->{code} = $exception->line->[1];
    $frames[0]->{context} = {
        pre  => [ map $_->[1], $exception->lines_before->@* ],
        post => [ map $_->[1], $exception->lines_after->@* ],
    };

    # keep value from stash more compact
    $exception->verbose(0);

    my $user = $c->stash('user');

    my $headers = $c->req->headers->to_hash(1);
    delete $headers->@{qw(Authorization Cookie jwt_token)};

    my $rollbar_id = create_uuid_str();
    my $request_id = length($c->req->url) ? $c->req->request_id : undef;

    # Payload documented at https://rollbar.com/docs/api/items_post/
    my $exception_payload = {
        access_token => $access_token,
        data         => {
            environment => $c->app->config('rollbar_environment') || 'development',
            body        => {
                trace => {
                    frames    => \@frames,
                    exception => {
                        class   => ref($exception),
                        message => $exception->message
                    }
                },
            },
            timestamp    => time,
            code_version => $c->version_hash,
            platform    => $c->tx->original_remote_address eq '127.0.0.1' ? 'client' : 'browser',
            language    => 'perl',
            request        => {
                url     => $c->req->url->to_abs->to_string,
                user_ip => $c->tx->original_remote_address,
                method  => $c->req->method,
                headers    => $headers,
                query_string => $c->req->query_params->to_string,
                charset => $c->req->content->charset || $c->req->default_charset,
                body    => $c->req->text,
            },
            server => {
                host => Sys::Hostname::hostname,
                root => $c->app->home->child('lib')->to_string
            },
            $user ? (person => { id => $user->id, username => $user->name, email => $user->email }) : (),

            custom => {
                request_id => $request_id,
                stash => +{
                    # we only go one level deep for most things, to avoid leaking
                    # potentially secret data.
                    map {
                        my $val = $c->stash($_);
                        $_ => $val eq 'mojo' || !ref $val ? $val : ($val.'');
                    }
                    keys $c->stash->%*,
                },
            },

            # see https://docs.rollbar.com/docs/grouping-algorithm
            fingerprint => join(':', map join(',', $_->@{qw(filename method lineno)}), @frames),

            uuid => $rollbar_id,
        }
    };

    # asynchronously post to Rollbar, log if the request fails
    my $log = $c->log;
    $c->ua->post(
        ROLLBAR_ENDPOINT,
        json => $exception_payload,
        sub ($ua, $tx) {
            if (my $err = $tx->error) {
                local $Conch::Log::REQUEST_ID = $request_id;
                $log->error('Unable to send exception to Rollbar. HTTP '
                    .$err->{code}." '$err->{message}'");
            }
        }
    );

    return $rollbar_id;
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
# vim: set ts=4 sts=4 sw=4 et :
