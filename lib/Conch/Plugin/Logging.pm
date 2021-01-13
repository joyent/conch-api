package Conch::Plugin::Logging;

use Mojo::Base 'Mojolicious::Plugin', -signatures;
use Conch::Log;
use Sys::Hostname;
use Mojo::File 'path';
use Time::HiRes 'time'; # time() now has µs precision

=pod

=head1 NAME

Conch::Plugin::Logging - Sets up logging for the application

=head1 METHODS

=head2 register

Initializes the logger object, and sets up hooks in various places to log request data and
process exceptions.

=head1 HELPERS

These methods are made available on the C<$c> object (the invocant of all controller methods,
and therefore other helpers).

=cut

sub register ($self, $app, $config) {
    my $plugin_config = $config->{logging} // {};

    my %LEVEL = (debug => 1, info => 2, warn => 3, error => 4, fatal => 5);
    die 'unrecognized log level '.$plugin_config->{level}
        if $plugin_config->{level} and not exists $LEVEL{$plugin_config->{level}};

    my ($log_to_stderr, $verbose) = delete $plugin_config->@{qw(log_to_stderr verbose)};

    my %log_args = (
        level => $ENV{MOJO_LOG_LEVEL} // 'debug',
        bunyan => 1,
        $verbose ? ( with_trace => 1 ) : (),
        $plugin_config->%*,
    );

    # without 'path' option, Mojo::Log defaults to *STDERR
    my $log_dir;
    if (not $log_to_stderr and not $log_args{handle}) {
        $log_dir = path($plugin_config->{dir} // 'log');
        $log_dir = $app->home->child($log_dir) if not $log_dir->is_abs;

        if (-d $log_dir) {
            return Mojo::Exception->throw('Cannot write to '.$log_dir) if not -w $log_dir;
        }
        else {
            print STDERR "Creating log dir $log_dir\n";
            $log_dir->dirname->make_path($log_dir);
        }

        $log_args{path} = $log_dir->child($app->mode.'.log');
    }

    $app->log(Conch::Log->new(%log_args));

    $app->plugin('AccessLog',
        log => $log_dir ? $log_dir->child('access.log') : $log_args{access_log_handle} // \*STDERR,
        # format => '%h %l %u %t "%r" %>s %b',  (default)
    );

=head2 log

Returns the main L<Conch::Log> object for the application, used for most logging.

=cut

    $app->helper(log => sub ($c) {
        return $c->stash->{'mojo.log'} //= $c->app->log;
    });

=head2 get_logger

Returns a secondary L<Conch::Log> object, to log specialized messages to a separate location.
Uses the provided C<type> in the filename (e.g. C<< type => foo >> will log to F<foo.log>).

=cut

    $app->helper(get_logger => sub ($c, $type, %additional_args) {
        Conch::Log->new(
            history => $c->app->log->history,   # share history buffers for ease of testing
            %log_args,                          # default arguments from config file
            $log_dir ? ( path => $log_dir->child($type.'.log') ) : (),
            %additional_args,
        );
    });

=head1 HOOKS

=head2 around_dispatch

Makes the request's request id available to the logger object.

=cut

    $app->hook(around_dispatch => sub ($next, $c) {
        local $Conch::Log::REQUEST_ID = $c->req->request_id;
        $next->();
    });

=head2 before_dispatch

Starts the C<request_latency> timer.

=cut

    $app->hook(before_dispatch => sub ($c) {
        $c->timing->begin('request_latency');
    });

=head2 after_dispatch

Logs the request and its response.

=cut

    my $dispatch_log = $app->get_logger('dispatch', bunyan => 1, with_trace => 0);
    my $exception_log = $app->get_logger('exception', bunyan => 1, with_trace => 0);

    $app->hook(after_dispatch => sub ($c) {
        my $u_str = $c->stash('user')
          ? $c->stash('user')->email.' ('.$c->stash('user')->id.')'
          : 'NOT AUTHED';

        my $req_headers = $c->req->headers->to_hash(1);
        $req_headers->{$_} = '--REDACTED--'
            foreach grep exists $req_headers->{$_}, qw(Authorization Cookie);

        my $res_headers = $c->res->headers->to_hash(1);
        $res_headers->{$_} = '--REDACTED--'
            foreach grep exists $res_headers->{$_}, qw(Set-Cookie);

        my $req_json = $c->req->json;
        my $res_json = $c->res->json;

        my $data = {
            msg => 'dispatch',
            api_version => $c->version_tag,
            req => {
                user        => $u_str,
                method      => $c->req->method,
                url         => $c->req->url,
                remoteAddress => $c->tx->remote_address,
                $c->req->reverse_proxy ? ( proxyAddress => $c->tx->original_remote_address ) : (),
                remotePort  => $c->tx->remote_port,
                headers     => $req_headers,
                query_params => $c->req->query_params->to_hash,
                # no body_params: presently we do not permit application/x-www-form-urlencoded
                !$verbose ? ()
                  : !defined $req_json ? ( body => $c->req->text )
                  : ref $req_json ne 'HASH' || !exists $req_json->{password} ? ( body => $req_json )
                  : ( body => +{ $req_json->%*, password => '--REDACTED--' } ),
            },
            res => {
                headers => $res_headers,
                statusCode => $c->res->code,
                !$verbose && $c->res->code < 400 ? ()
                  : !defined $res_json ? ( body => $c->res->text )
                  : (ref $res_json ne 'HASH' || !grep /token/, keys $res_json->%*)
                    ? ( body => $res_json )
                  : ( body => +{ $res_json->%*,
                      map +($_ => '--REDACTED--'), grep /token/, keys $res_json->%* } ),
            },
            latency => int(1000 * $c->timing->elapsed('request_latency')),
        };

        if (my $exception = $c->stash('exception')) {
            my @frames = map +{
                class => $_->[0],
                file  => $_->[1],
                line  => $_->[2],
                func  => $_->[3],
            },
            reverse $exception->frames->@*;

            $data->{err} = {
                msg     => $exception->to_string,
                frames  => \@frames,
            };
        }

        $c->app->plugins->emit(dispatch_message_payload => $c, $data);

        local $Conch::Log::REQUEST_ID = $c->req->request_id;
        $dispatch_log->info($data);

        if ($c->stash('exception')) {
            delete $data->@{qw(msg latency)};
            $exception_log->error($data);
        }
    });
}

1;
__END__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<https://www.mozilla.org/en-US/MPL/2.0/>.

=cut
# vim: set sts=2 sw=2 et :
