=pod

=head1 NAME

Conch - Setup and helpers for Conch Mojo app

=head1 SYNOPSIS

  Mojolicious::Commands->start_app('Conch');

=head1 METHODS

=cut

package Conch;
use Mojo::Base 'Mojolicious', -signatures;

use Conch::Route;
use Mojolicious::Plugin::Bcrypt;
use Conch::ValidationSystem;
use Mojo::JSON;

=head2 startup

Used by Mojo in the startup process. Loads the config file and sets up the
helpers, routes and everything else.

=cut

sub startup {
    my $self = shift;

    # Configuration
    $self->plugin('Config');
    $self->secrets($self->config('secrets'));
    $self->sessions->cookie_name('conch');
    $self->sessions->default_expiration(2592000);    # 30 days

    $self->plugin('Conch::Plugin::Features', $self->config);
    $self->plugin('Conch::Plugin::Logging', $self->config);
    $self->plugin('Conch::Plugin::Database', $self->config);

    # specify which MIME types we can handle
    $self->types->type(json => 'application/json');
    $self->types->type(csv => 'text/csv');


    $self->hook(
        before_render => sub ($c, $args) {
            my $template = $args->{template};
            return if not $template;

            if ($template =~ /exception/) {
                return $args->{json} = { error => 'An exception occurred' };
            }
            if ($args->{template} =~ /not_found/) {
                return $args->{json} = { error => 'Not Found' };
            }
        }
    );


    $self->helper(
        status => sub ($c, $code, $payload = undef) {
            $payload //= { error => 'Unauthorized' } if $code == 401;
            $payload //= { error => 'Forbidden' } if $code == 403;
            $payload //= { error => 'Not Found' } if $code == 404;
            $payload //= { error => 'Unimplemented' } if $code == 501;

            if (not $payload) {
                # no content - hopefully we set a 204 response code
                $c->rendered($code);
                return 0;
            }

            $c->res->code($code);

            if ($code == 303) {
                $c->redirect_to($c->url_for($payload));
            }
            else {
                $c->respond_to(
                    json => { json => $payload },
                    any  => { json => $payload },
                );
            }

            return 0;
        }
    );


    $self->hook(
        before_routes => sub ($c) {
            my $headers = $c->req->headers;

            # Check only applies to requests with payloads (Content-Length
            # header is specified and greater than 0). Content-Type header must
            # be specified and must be 'application/json' for all payloads, or
            # HTTP status code 415 'Unsupported Media Type' is returned.
            if ($headers->content_length) {
                unless ($headers->content_type
                    && $headers->content_type =~ /application\/json/i) {
                    return $c->status(415);
                }
            }
        }
    );

    $self->hook(
        before_dispatch => sub ($c) {
            my $headers = $c->res->headers;
            my $request_id = $c->req->request_id;
            $headers->header('Request-Id' => $request_id);
            $headers->header('X-Request-Id' => $request_id);
        }
    );

    $self->plugin('Util::RandomString' => {
        alphabet => '2345679bdfhmnprtFGHJLMNPRT*#!@^-_+=',
        length => 30
    });

    $self->plugin('Conch::Plugin::GitVersion', $self->config);
    $self->plugin('Conch::Plugin::JsonValidator', $self->config);
    $self->plugin('Conch::Plugin::AuthHelpers', $self->config);
    $self->plugin('Conch::Plugin::Mail', $self->config);

    $self->plugin(NYTProf => $self->config) if $self->feature('nytprof');
    $self->plugin('Conch::Plugin::Rollbar', $self->config) if $self->feature('rollbar');

    push @{$self->commands->namespaces}, 'Conch::Command';

    Conch::ValidationSystem->new(log => $self->log, schema => $self->ro_schema)
        ->check_validation_plans;

    Conch::Route->all_routes($self->routes);
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
# vim: set ts=4 sts=4 sw=4 et :
