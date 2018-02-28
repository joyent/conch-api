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
use Mojo::Pg;
use Mojolicious::Plugin::Bcrypt;
use Data::Printer;

use Mojo::JSON;

=head2 startup

Used by Mojo in the startup process. Loads the config file and sets up the
helpers

=cut

sub startup {
	my $self = shift;

	# Configuration
	$self->plugin('Config');
	$self->secrets( $self->config('secrets') );
	$self->sessions->cookie_name('conch');
	$self->sessions->default_expiration(2592000);    # 30 days

	# Log all messages regardless of operating mode
	$self->log->level('debug');
	Conch::Pg->new($self->config('pg'));

	$self->helper(
		status => sub {
			my ( $self, $code, $payload ) = @_;
			my $c = $self->app;
			my $tx = $self->tx;

			my $u = $self->stash('user');
			my $u_str = $u ?
				$u->email . " (".$u->id.")" :
				'NOT AUTHED';

			my $msg = join(" || ",
				"URL: ".$tx->req->url->to_abs,
				"Code: $code",
				"Source: ".$tx->original_remote_address.":".$tx->remote_port,
				"User: $u_str",
			);

			if ($code >= 400) {
				$msg = "$msg || Payload: ".Mojo::JSON::to_json($payload);
				$c->log->warn($msg);
			} else {
				$c->log->info($msg);
			}

			$self->res->code($code);
			if ( ( $code == 403 ) && !$payload ) {
				$payload = { error => "Forbidden" };
			}

			return $payload ? $self->render( json => $payload ) : $self->finish;
		}
	);

	$self->helper(
		global_auth => sub {
			my ( $c, $role_name ) = @_;
			return 0 unless $c->stash('user_id');

			my $ws = $c->workspace->lookup_by_name('GLOBAL');
			return 0 unless $ws;

			my $user_ws =
				$c->workspace->get_user_workspace( $c->stash('user_id'), $ws->id, );

			return 0 unless $user_ws;
			return 0 unless $user_ws->role eq $role_name;
			return 1;
		},
	);

	$self->helper(
		is_global_admin => sub {
			shift->global_auth('Administrator');
		}
	);

	my $unparsable_report_logger = Mojo::Log->new(
		path   => "log/unparsable_report.log",
		format => sub {
			my ( $time, undef, @lines ) = @_;
			$time = localtime($time);
			return map { "[$time] " . $_ . "\n" } @lines;
		}
	);
	$self->helper(
		log_unparsable_report => sub {
			my ( undef, $report, $errs ) = @_;
			$unparsable_report_logger->error(
				'Failed parsing device report: ' . $errs );
			$unparsable_report_logger->error(
				"Device Report: " . Mojo::JSON::encode_json($report) );
		}
	);

	# Render exceptions and Not Found as JSON
	$self->hook(
		before_render => sub {
			my ( $c, $args ) = @_;
			return unless my $template = $args->{template};
			if ( $template =~ /exception/ ) {
				my $exception = $args->{exception};
				$exception->verbose(1);
				$self->log->error($exception);
				my @stack = @{ $exception->frames };
				@stack = map { "\t" . $_->[3] . ' at ' . $_->[1] . ':' . $_->[2] }
					grep defined, @{ $exception->frames }[ 0 .. 10 ];
				$self->log->error(
					"Stack Trace (first 10 frames):\n" . join( "\n", @stack ) );
				return $args->{json} = { error => 'Something went wrong' };
			}
			if ( $args->{template} =~ /not_found/ ) {
				return $args->{json} = { error => 'Not Found' };
			}
		}
	);

	$self->plugin('Util::RandomString');
	$self->plugin('Conch::Plugin::Model');
	$self->plugin('Conch::Plugin::Mail');
	$self->plugin(NYTProf => $self->config);

	if($self->config('audit')) {
		my $log_path = $self->config('audit_log_path') || 'log/audit.log';
		my $log = Mojo::Log->new(path => $log_path);
		$self->hook(after_dispatch => sub {
			my $c = shift;
			my $d = {
				remote_ip   => $c->tx->original_remote_address,
				remote_port => $c->tx->remote_port,
				url         => $c->req->url->to_abs,
				method      => $c->req->method,
				request     => {
					headers => $c->req->headers->to_hash,
					body    => $c->req->body,
					cookies => $c->req->cookies,
					params  => $c->req->params->to_hash,
				},
				response    => {
					headers => $c->res->headers->to_hash,
					cookies => $c->res->cookies,
					body    => $c->res->body,
				},
			};
			$log->debug(Mojo::JSON::to_json($d));
		});
	}

	my $r = $self->routes;
	all_routes($r);
}

1;

__DATA__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.

=cut
