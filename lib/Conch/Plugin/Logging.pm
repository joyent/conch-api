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

=cut

sub register ($self, $app, $config) {
    my $plugin_config = $config->{logging} // {};
    my $log_dir = $plugin_config->{dir} // 'log';

    my %log_args = (
        level => 'debug',
        bunyan => 1,
        $app->feature('audit') ? ( with_trace => 1 ) : (),
        $plugin_config->%*,
    );

    # without 'path' option, Mojo::Log defaults to *STDERR
    if (not $app->feature('log_to_stderr')) {
        $log_dir = path($log_dir);
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

    $app->helper(log => sub ($c) { $c->app->log });

    $app->hook(around_dispatch => sub ($next, $c) {
        local $Conch::Log::REQUEST_ID = $c->req->request_id;
        $next->();
    });

    $app->hook(before_dispatch => sub ($c) {
        $c->timing->begin('request_latency');
    });

    my $dispatch_log = Conch::Log->new(
        history => $app->log->history,  # share history buffers
        %log_args,
        bunyan => 1,
        with_trace => 0,
    );

    $app->hook(after_dispatch => sub ($c) {
        my $u_str = $c->stash('user')
          ? $c->stash('user')->email.' ('.$c->stash('user')->id.')'
          : 'NOT AUTHED';

        my $req_headers = $c->req->headers->to_hash(1);
        delete $req_headers->@{qw(Authorization Cookie jwt_token jwt_sig)};

        my $res_headers = $c->res->headers->to_hash(1);
        delete $res_headers->@{qw(Set-Cookie)};

        my $req_json = $c->req->json;
        my $res_json = $c->res->json;

        my $data = {
            msg => 'dispatch',
            api_version => $c->version_tag,
            req => {
                user        => $u_str,
                method      => $c->req->method,
                url         => $c->req->url,
                remoteAddress => $c->tx->original_remote_address,
                remotePort  => $c->tx->remote_port,
                headers     => $req_headers,
                query_params => $c->req->query_params->to_hash,
                # no body_params: presently we do not permit application/x-www-form-urlencoded
                $c->feature('audit') && !(ref $req_json eq 'HASH' and exists $req_json->{password})
                    ? ( body => $c->req->json // $c->req->text ) : (),
            },
            res => {
                headers => $res_headers,
                statusCode => $c->res->code,
                $c->res->code >= 400
                        || ($c->feature('audit') && !(ref $res_json eq 'HASH' and grep /token/, keys $res_json->%*))
                    ? ( body => $c->res->json // $c->res->text ) : (),
            },
            latency => int(1000 * $c->timing->elapsed('request_latency')),
        };

        if (my $exception = $c->stash('exception')) {
            $exception->verbose;
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

        local $Conch::Log::REQUEST_ID = $c->req->request_id;
        $dispatch_log->info($data);
    });
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
