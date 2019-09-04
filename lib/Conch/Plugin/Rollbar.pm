package Conch::Plugin::Rollbar;

use Mojo::Base 'Mojolicious::Plugin', -signatures;
use Sys::Hostname ();
use Conch::UUID 'create_uuid_str';
use WebService::Rollbar::Notifier;
use Digest::SHA ();
use Config;
use Mojo::JSON 'to_json';
use List::Util 'none';
use Carp;

my @message_levels = qw(critical error warning info debug);

=pod

=head1 NAME

Conch::Plugin::Rollbar

=head1 DESCRIPTION

Mojo plugin to send messages and exceptions to L<Rollbar|https://rollbar.com>.

=head1 HOOKS

=head2 before_render

Sends exceptions to Rollbar.

=cut

sub register ($self, $app, $config) {

    $app->hook(before_render => sub ($c, $args) {
        my $template = $args->{template};

        if (my $exception = $c->stash('exception')
                or ($template and $template =~ /exception/)) {
            $exception //= $args->{exception};
            my $rollbar_id = $c->send_exception_to_rollbar($exception);
            $c->log->debug('exception sent to rollbar: id '.$rollbar_id);
        }
    });


=head1 HELPERS

=head2 send_exception_to_rollbar

Asynchronously send exception details to Rollbar (if the C<rollbar> C<access_token> is
configured).  Returns a unique uuid suitable for logging, to correlate with the Rollbar entry
thus created.

=cut

    # this is cached at the app level, rather than for the entire interpreter runtime
    my $notifier;

    $app->helper(send_exception_to_rollbar => sub ($c, $exception) {
        $notifier //= _create_notifier($c->app, $c->config);
        return if not $notifier;

        my @frames = map +{
            class_name => $_->[0],
            filename   => $_->[1],
            lineno     => $_->[2],
            method     => $_->[3],
        },
        $exception->frames->@*;

        if (@frames) {
            # we only have context for the first frame.
            # Mojo::Exception data contains line numbers as well.
            $frames[0]->{code} = $exception->line->[1];
            $frames[0]->{context} = {
                pre  => [ map $_->[1], $exception->lines_before->@* ],
                post => [ map $_->[1], $exception->lines_after->@* ],
            };
        }

        my $rollbar_id = create_uuid_str();

        # see https://docs.rollbar.com/docs/grouping-algorithm
        my $fingerprint = join(':',
            $exception->message,
            map join(',', $_->@{qw(filename method lineno)}), @frames,
        );
        $fingerprint = Digest::SHA::sha1_hex($fingerprint) if length($fingerprint) > 40;

        # asynchronously post to Rollbar, logging if the request fails
        $notifier->report_trace(
            ref($exception),
            $exception->message,
            \@frames,
            {
                fingerprint => $fingerprint,
                uuid => $rollbar_id,
                _get_extra_data($c)->%*,
            },
        );

        return $rollbar_id;
    });

=head2 send_message_to_rollbar

Asynchronously send a message to Rollbar (if the C<rollbar> C<access_token> is configured).
Returns a unique uuid suitable for logging, to correlate with the Rollbar entry thus created.

Requires a message string. A hashref of additional data is optional.

=cut

    $app->helper(send_message_to_rollbar => sub ($c, $severity, $message_string, $payload = {}) {
        Carp::croak('severity must be one of: '.join(', ',@message_levels))
            if !$ENV{MOJO_MODE} and none { $severity eq $_ } @message_levels;

        $notifier //= _create_notifier($c->app, $c->config);
        return if not $notifier;

        my $rollbar_id = create_uuid_str();

        # see https://docs.rollbar.com/docs/grouping-algorithm
        my $fingerprint = join(',',
            $message_string,
            to_json($payload),
        );
        $fingerprint = Digest::SHA::sha1_hex($fingerprint) if length($fingerprint) > 40;

        # asynchronously post to Rollbar, logging if the request fails
        $notifier->report_message(
            [ $message_string, $payload ],
            {
                fingerprint => $fingerprint,
                uuid => $rollbar_id,
                level => $severity,
                _get_extra_data($c)->%*,
            },
        );

        return $rollbar_id;
    });
}

sub _get_extra_data ($c) {
    my $user = $c->stash('user');
    my $headers = $c->req->headers->to_hash(1);
    delete $headers->@{qw(Authorization Cookie jwt_token)};

    +{
        length($c->req->url) ? (
            request => {
                url     => $c->req->url->to_abs->to_string,
                user_ip => $c->tx->original_remote_address,
                method  => $c->req->method,
                headers    => $headers,
                query_string => $c->req->query_params->to_string,
                charset => $c->req->content->charset || $c->req->default_charset,
                body    => $c->req->text,
                # TODO, when we store these values in the stash via a common shortcut:
                # GET => $c->stash('parsed_query_params'),
                # POST => $c->stash('parsed_body_params'),
            },
            $c->stash('action') ? (context => ($c->stash('controller')//'').'#'.$c->stash('action')): (),
        ) : (),
        $user ? (person => { id => $user->id, username => $user->name, email => $user->email }) : (),

        custom => {
            request_id => (length($c->req->url) ? $c->req->request_id : undef),
            stash => +{
                # we only go one level deep, to avoid leaking potentially secret data.
                map {
                    my $val = $c->stash($_);
                    $_ => ref $val ? ($val.'') : $val;
                }
                grep $_ ne 'exception' && $_ ne 'snapshot' && !/^mojo\./,
                keys $c->stash->%*,
            },
        },
    };
}

sub _create_notifier ($app, $config) {
    my $access_token = $config->{rollbar}{access_token};
    if (not $access_token) {
        $app->log->warn('Unable to send exception to Rollbar - no access token configured');
        return;
    }
    WebService::Rollbar::Notifier->new(
        access_token => $access_token,
        environment => $config->{rollbar}{environment} // $app->mode,
        code_version => $app->version_hash,
        language => 'perl '.$Config{version},
        server => {
            host => Sys::Hostname::hostname,
            root => $app->home->child('lib')->to_string,
            (map +($_ => $Config{$_}), qw(perlpath archname osname osvers)),
        },
        _ua => $app->ua,

        callback => sub ($ua, $tx) {
            if (!$ENV{MOJO_MODE}) {
                my $validator = JSON::Validator->new->load_and_validate_schema(
                    'json-schema/other.yaml',
                    { schema => 'http://json-schema.org/draft-07/schema#' });
                my $schema = $validator->get('/definitions/RollbarPayload');
                if (my @errors = $validator->validate($tx->req->json, $schema)) {
                    require Data::Dumper;
                    Carp::croak('validation error: '
                        .Data::Dumper->new([ [ map $_->TO_JSON, @errors ] ])
                            ->Indent(1)->Terse(1)->Sortkeys(1)->Dump);
                }
            }

            if (my $err = $tx->error) {
                my $request_id = length($tx->req->url) ? $tx->req->request_id : undef;
                local $Conch::Log::REQUEST_ID = $request_id;
                $ua->server->app->log->error('Unable to send exception to Rollbar.'
                    .($err->{code} ? (' HTTP '.$err->{code}) : '')
                    ." '$err->{message}'");
            }
        },
    );
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
