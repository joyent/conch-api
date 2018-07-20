=pod

=head1 NAME

Conch::Plugin::Rollbar

=head1 DESCRIPTION

Mojo plugin to send exceptions to L<Rollbar|https://rollbar.com>

=head1 METHODS

=cut

package Conch::Plugin::Rollbar;

use Mojo::Base 'Mojolicious::Plugin', -signatures;
use Sys::Hostname;

use constant ROLLBAR_ENDPOINT => 'https://api.rollbar.com/api/1/item/';

=head2 register

Adds `send_exception_to_rollbar` to Mojolicious app

=cut

sub register ( $self, $app, $conf ) {
	$app->helper( send_exception_to_rollbar => sub { _record_exception(@_) } );
}

# asynchronously send exception details to Rollbar if 'rollbar_access_token' is
# specified in the commit
sub _record_exception ( $c, $exception ) {
	my $access_token = $c->app->config('rollbar_access_token') || return;
	my $environment  = $c->app->config('rollbar_environment')  || 'development';

	my @frames = map {
		{
			class_name => $_->[0],
			filename   => $_->[1],
			lineno     => $_->[2],
			method     => $_->[3],
		}
	} $exception->frames->@*;

	my $context = {
		context => {
			pre  => $exception->lines_before,
			post => $exception->lines_after
		}
	};

	# We only have context for the first frame
	$frames[0]->{context} = $context;

	my $user   = $c->stash(' user ');
	my @person = (
		person => {
			id    => $user->id,
			email => $user->email
		}
	) if $user;

	# Payload documented at https://rollbar.com/docs/api/items_post/
	my $exception_payload = {
		access_token => $access_token,
		data         => {
			environment => $environment,
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
			platform     => $^O,
			request      => {
				url     => $c->req->url->to_abs,
				user_ip => $c->tx->original_remote_address,
				method  => $c->req->method
			},
			server => {
				host => hostname(),
				root => $c->app->home->child('lib')->to_string
			},
			@person,
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
