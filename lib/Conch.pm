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
use Conch::ValidationSystem;
use List::Util 'any';
use Digest::SHA ();

=head2 startup

Used by Mojo in the startup process. Loads the config file and sets up the
helpers, routes and everything else.

=head1 HELPERS

These methods are made available on the C<$c> object (the invocant of all controller methods,
and therefore other helpers).

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
    $self->plugin('Conch::Plugin::GitVersion', $self->config);
    $self->plugin('Conch::Plugin::Database', $self->config);

    # specify which MIME types we can handle
    $self->types->type(json => 'application/json');
    $self->types->type(csv => 'text/csv');


    $self->hook(before_render => sub ($c, $args) {
        if (my $template = $args->{template}) {
            if ($template =~ /exception/) {
                delete $args->{template};
                $args->{json} = { error => 'An exception occurred' };
            }
            elsif ($args->{template} =~ /not_found/) {
                delete $args->{template};
                $args->{json} = { error => 'Not Found' };
            }
        }

        $c->send_message_to_rollbar(
            'info',
            'response payload contains many elements: candidate for paging?',
            {
                elements => scalar $args->{json}->@*,
                endpoint => join('#', map $_//'', $c->match->stack->[-1]->@{qw(controller action)}),
                url => $c->url_for,
            },
        )
            if ref $args->{json} eq 'ARRAY'
                # TODO: skip if ?page_size is passed (and we actually used it).
                and $args->{json}->@* >= ($c->app->config->{rollbar}{warn_payload_elements} // 35)
                and $c->feature('rollbar');

        # do this after the response has been sent
        $c->on(finish => sub ($c) {
            my $body_size = $c->res->body_size;
            $c->send_message_to_rollbar(
                'info',
                'response payload size is large: candidate for paging or refactoring?',
                {
                    bytes => $body_size,
                    endpoint => join('#', map $_//'', $c->match->stack->[-1]->@{qw(controller action)}),
                    url => $c->url_for,
                },
            )
                if $body_size >= ($c->app->config->{rollbar}{warn_payload_size} // 10000)
                    and $c->feature('rollbar');
        });
    });

    $self->hook(after_render => sub ($c, @args) {
        warn 'called $c->render twice' if $c->stash->{_rendered}++;

        $c->res->headers->add('X-Conch-API', $c->version_tag);
    });

=head2 status

Helper method for setting the response status code and json content.

=cut

    $self->helper(status => sub ($c, $code, $payload = undef) {
        $payload //= { error => (split(/\n/, $c->stash('exception'), 2))[0] }
            if $code >= 400 and $code < 500 and $c->stash('exception');

        $payload //= { error => 'Unauthorized' } if $code == 401;
        $payload //= { error => 'Forbidden' } if $code == 403;
        $payload //= { error => 'Not Found' } if $code == 404;
        $payload //= { error => 'Unimplemented' } if $code == 501;

        if (not $payload) {
            # no content - hopefully we set an appropriate response code (e.g. 204, 30x)
            $c->rendered($code);
            return 0;
        }

        $c->res->code($code);

        if (any { $code == $_ } 301, 302, 303, 305, 307, 308) {
            $c->redirect_to($payload);
        }
        else {
            $c->respond_to(
                json => { json => $payload },
                any  => { json => $payload },
            );
        }

        return 0;
    });


    $self->hook(before_routes => sub ($c) {
        my $headers = $c->req->headers;

        # Check only applies to requests with payloads (Content-Length
        # header is specified and greater than 0). Content-Type header must
        # be specified and must be 'application/json' for all payloads, or
        # HTTP status code 415 'Unsupported Media Type' is returned.
        if ($headers->content_length
                and (not $headers->content_type
                    or $headers->content_type !~ /application\/json/i)) {
            return $c->status(415);
        }
    });

    $self->hook(before_dispatch => sub ($c) {
        my $headers = $c->res->headers;
        my $request_id = $c->req->request_id;
        $headers->header('Request-Id' => $request_id);
        $headers->header('X-Request-Id' => $request_id);
    });

    # see Mojo::Message::Request for original implementation
    my ($SEED, $COUNTER) = ($$ . time . rand, int rand 0xffffff);
    $self->hook(after_build_tx => sub ($tx, $app) {
        my $checksum = Digest::SHA::sha1_base64($SEED . ($COUNTER = ($COUNTER + 1) % 0xffffff));
        $tx->req->request_id(substr $checksum, 0, 12);
    });


    $self->plugin('Conch::Plugin::ClientVerification', $self->config)
        if $self->feature('verify_client_version') // 1;

    $self->plugin('Util::RandomString' => {
        alphabet => '2345679bdfhmnprtFGHJLMNPRT*#!@^-_+=',
        length => 30
    });

    $self->plugin('Conch::Plugin::JsonValidator', $self->config);
    $self->plugin('Conch::Plugin::AuthHelpers', $self->config);
    $self->plugin('Conch::Plugin::Mail', $self->config);

    $self->plugin(NYTProf => $self->config) if $self->feature('nytprof');
    $self->plugin('Conch::Plugin::Rollbar', $self->config) if $self->feature('rollbar');

=head2 startup_time

Stores a L<Conch::Time> instance representing the time the server started accepting requests.

=cut

    my $startup_time = Conch::Time->now;
    $self->helper(startup_time => sub ($c) { $startup_time });

=head2 host

Retrieves the L<Mojo::URL/host> portion of the request URL, suitable for constructing email
addresses and base URLs in user-facing content.

=cut

    $self->helper(host => sub ($c) { $c->req->url->base->host });

    push $self->commands->namespaces->@*, 'Conch::Command';

    Conch::ValidationSystem->new(log => $self->log, schema => $self->ro_schema)
            ->check_validation_plans
        if not $self->feature('no_db');

    Conch::Route->all_routes($self->routes, $self);
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
