package Conch::Plugin::Rollbar;

use Mojo::Base 'Mojolicious::Plugin', -signatures;
use Sys::Hostname;
use Data::UUID;

use constant ROLLBAR_ENDPOINT => 'https://api.rollbar.com/api/1/item/';

=pod

=head1 NAME

Conch::Plugin::Rollbar

=head1 DESCRIPTION

Mojo plugin to send exceptions to L<Rollbar|https://rollbar.com>

=head1 METHODS

=head2 register

Adds `send_exception_to_rollbar` to Mojolicious app

=cut

sub register ($self, $app, @) {
	$app->helper(send_exception_to_rollbar => \&_record_exception);
}

# asynchronously send exception details to Rollbar if 'rollbar_access_token' is
# configured
sub _record_exception ($c, $exception, @) {
	my $access_token = $c->config('rollbar_access_token');
	if (not $access_token) {
		$c->app->log->warn('Unable to send exception to Rollbar - no access token configured');
		return;
	}

	my @frames = map {
		{
			class_name => $_->[0],
			filename   => $_->[1],
			lineno     => $_->[2],
			method     => $_->[3],
		}
	} $exception->frames->@*;

	# we only have context for the first frame.
	# Mojo::Exception data contains line numbers as well.
	$frames[0]->{code} = $exception->line->[1];
	$frames[0]->{context} = {
		pre  => [ map { $_->[1] } $exception->lines_before->@* ],
		post => [ map { $_->[1] } $exception->lines_after->@* ],
	};

	# keep value from stash more compact
	$exception->verbose(0);

	my $user = $c->stash('user');

	my $headers = $c->req->headers->to_hash(1);
	delete $headers->@{qw(Authorization Cookie jwt_token jwt_sig)};

	# Payload documented at https://rollbar.com/docs/api/items_post/
	my $exception_payload = {
		access_token => $access_token,
		data         => {
			environment => $c->config('rollbar_environment') || 'development',
			body        => {
				trace => {
					frames    => \@frames,
					exception => {
						class   => ref($exception),
						message => $exception->message
					}
				},
			},
			timestamp    => time(),
			code_version => $c->version_hash,
			platform    => $c->tx->original_remote_address eq '127.0.0.1' ? 'client' : 'browser',
			language    => 'perl',
			request		=> {
				url     => $c->req->url->to_abs->to_string,
				user_ip => $c->tx->original_remote_address,
				method  => $c->req->method,
				headers	=> $headers,
				query_string => $c->req->query_params->to_string,
				body	=> $c->req->body,
			},
			server => {
				host => hostname(),
				root => $c->app->home->child('lib')->to_string
			},
			$user ? (person => { id => $user->id, username => $user->name, email => $user->email }) : (),

			custom => {
				request_id => $c->req->request_id,

				# some of these things are objects, so we just go one level deep for now.
				stash => +{
					map { $_ => ($c->stash($_) // '') . '' } keys $c->stash->%*
				},
			},

			# see https://docs.rollbar.com/docs/grouping-algorithm
			fingerprint => join(':', map { join(',', $_->@{qw(filename method lineno)}) } @frames),

			uuid => Data::UUID->new->create_str,
		}
	};

	# asynchronously post to Rollbar, log if the request fails
	$c->app->ua->post(
		ROLLBAR_ENDPOINT,
		json => $exception_payload,
		sub {
			my ( $ua, $tx ) = @_;
			if ( my $err = $tx->error ) {
				$c->app->log->error( "Unable to send exception to Rollbar."
						. " HTTP $err->{code} '$err->{message} " );
			}
		}
	);
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
