=pod

=head1 NAME

Conch - Setup and helpers for Conch Mojo app

=head1 SYNOPSIS

  Mojolicious::Commands->start_app('Conch');

=head1 METHODS

=cut

package Conch;
use Mojo::Base 'Mojolicious';

use Conch::Pg;
use Conch::Route qw(all_routes);
use Mojolicious::Plugin::Bcrypt;

use Conch::Models;
use Conch::ValidationSystem;
use Conch::Plugin::AuthHelpers;
use Conch::Plugin::JsonValidator;

use Conch::DB qw();

use Mojo::JSON;
use Lingua::EN::Inflexion 'noun';
use Mojo::Util 'decamelize';

=head2 startup

Used by Mojo in the startup process. Loads the config file and sets up the
helpers, routes and everything else.

=cut

sub startup {
	my $self = shift;

	# Configuration
	$self->plugin('Config');
	$self->secrets( $self->config('secrets') );
	$self->sessions->cookie_name('conch');
	$self->sessions->default_expiration(2592000);    # 30 days

	$self->plugin('Conch::Plugin::Logging');

	# Initialize singletons
	Conch::Pg->new($self->config('pg'));

	# Provide access to DBIx::Class
	$self->helper(schema => sub {
		my $db = Conch::Pg->new();
		return Conch::DB->connect(
			$db->dsn,
			$db->username,
			$db->password,
		);
	});

	# db_user_accounts => $app->schema->resultset('UserAccount'), etc
	foreach my $source ($self->schema->sources) {
		# necessary for now due to RT#125930
		my @words = split(/_/, decamelize($source));
		$words[-1] = noun($words[-1])->plural;
		my $name = join('_', @words);
		$self->helper('db_'.$name, sub {
			shift->app->schema->resultset($source)
		});
	}

	my %features = $self->config('features') ?
		$self->config('features')->%* : () ;

	$self->hook(
		before_render => sub {
			my ( $c, $args ) = @_;
			my $template = $args->{template};
			return if not $template;

			if ( $template =~ /exception/ ) {
				return $args->{json} = { error => "An exception occurred" };
			}
			if ( $args->{template} =~ /not_found/ ) {
				return $args->{json} = { error => 'Not Found' };
			}
		}
	);



	$self->helper(
		status => sub {
			my ( $c, $code, $payload ) = @_;

			$c->res->code($code);

			unless ($payload) {
				if ($code == 403) {
					$payload = { error => "Forbidden" };
				}

				if ($code == 501) {
					$payload = { error => "Unimplemented" };
				}
			}

			if($payload) {
				if ($code == 303) {
					$c->redirect_to( $c->url_for($payload) );
					return $c->finish;
				}

				return $c->respond_to(
					json => { json => $payload },
					any  => { json => $payload },
				);
			} else {
				return $c->finish;
			}
		}
	);


	$self->hook(
		# Preventative check against CSRF. Cross-origin requests can only
		# specify application/x-www-form-urlencoded, multipart/form-data,
		# and text/plain Content Types without triggering CORS checks in the browser.
		# Appropriate CORS headers must still be added by the serving proxy
		# to be effective against CSRF.
		before_routes => sub {
			my $c = shift;
			my $headers = $c->req->headers;

			# Check only applies to requests with payloads (Content-Length
			# header is specified and greater than 0). Content-Type header must
			# be specified and must be 'application/json' for all payloads, or
			# HTTP status code 415 'Unsupported Media Type' is returned.
			if ( $headers->content_length ) {
				unless ( $headers->content_type
					&& $headers->content_type =~ /application\/json/i) {
					return $c->status(415);
				}
			}
		}
	);


	# This sets CORS headers suitable for development. More restrictive headers
	# *should* be added by a reverse-proxy for production deployments.
	# This will set 'Access-Control-Allow-Origin' to the request Origin, which
	# means it's vulnerable to CSRF attacks. However, for developing browser
	# apps locally, this is a necessary evil.
	if ($self->mode eq 'development') {
		$self->hook(
			after_dispatch => sub {
				my $c = shift;
				my $origin = $c->req->headers->origin || '*';
				$c->res->headers->header( 'Access-Control-Allow-Origin' => $origin );
				$c->res->headers->header(
					'Access-Control-Allow-Methods' => 'GET, PUT, POST, DELETE, OPTIONS' );
				$c->res->headers->header( 'Access-Control-Max-Age' => 3600 );
				$c->res->headers->header( 'Access-Control-Allow-Headers' =>
						'Content-Type, Authorization, X-Requested-With' );
				$c->res->headers->header( 'Access-Control-Allow-Credentials' => 'true' );
			}
		);
	}

	$self->plugin('Util::RandomString' => {
		alphabet => '2345679bdfhmnprtFGHJLMNPRT*#!@^-_+=',
		length => 30
	});

	$self->plugin('Conch::Plugin::Mail');
	$self->plugin('Conch::Plugin::GitVersion');
	$self->plugin(NYTProf => $self->config);
	$self->plugin('Conch::Plugin::JsonValidator');
	$self->plugin("Conch::Plugin::AuthHelpers");

	if($features{'rollbar'}) {
		$self->plugin('Conch::Plugin::Rollbar');
	}

	push @{$self->commands->namespaces}, 'Conch::Command';

	Conch::ValidationSystem->load_validations( $self->log );

	all_routes($self->routes, \%features);
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
