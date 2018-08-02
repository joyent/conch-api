=head1 NAME

Conch::Plugin::Logging - Sets up logging for the application

=head1 METHODS

=cut

package Conch::Plugin::Logging;

use Mojo::Base 'Mojolicious::Plugin', -signatures;
use Mojo::Log;
use Conch::Log;

use Mojo::JSON;
use Sys::Hostname;

=head2 register
=cut

sub register ($self, $app, $conf) {

	my %features = $app->config('features') ?
		$app->config('features')->%* : () ;

	my $home = $app->home;
	my $mode = $app->mode;
	my $log_dir = $home->child('log');

	if(-d $log_dir) {
		unless(-w $log_dir) {
			return Mojo::Exception->throw("Cannot write to $log_dir");
		}
	} else {
		if(-w $home->path) {
			$app->log->info("Creating log dir $log_dir");
			$home->make_path($log_dir);
		} else { 
			return Mojo::Exception->throw("Cannot create $log_dir");
		}
	}
	my $log_path = $home->child('log', "$mode.log");

	$app->log(Conch::Log->new(
		path       => $log_path,
		level      => 'debug',
    ));

	if($features{rollbar}) {
		$app->hook(
			before_render => sub {
				my ( $c, $args ) = @_;
				my $template = $args->{template};
				return if not $template;
				if ( $template =~ /exception/ ) {
					my $exception = $c->stash('exception') // $args->{exception};
					$exception->verbose(1);

					$app->send_exception_to_rollbar($exception);
				}
			}
		);
	}

	$app->hook(after_dispatch => sub {
		my $c = shift;

		my $u_str = $c->stash('user') ?
			$c->stash('user')->email . " (".$c->stash('user')->id.")" :
			'NOT AUTHED';

		my $req_headers = $c->tx->req->headers->to_hash;
		for (qw(Authorization Cookie jwt_token jwt_sig)) {
			delete $req_headers->{$_};
		}

		my $log = {
			v        => 1,
			pid      => $$,
			hostname => hostname,
			time     => Conch::Time->now->iso8601,
			level    => 'info',
			msg      => 'dispatch',
			name     => 'conch-api',
			req_id   => $c->req->request_id,
			src      => {
				func => __PACKAGE__,
			},
			req => {
				user         => $u_str,
				method       => $c->req->method,
				url          => $c->req->url,
				remoteAdress => $c->tx->original_remote_address,
				remotePort   => $c->tx->remote_port,
				headers      => $req_headers,
				params       => $c->req->params->to_hash,
			},
		};

		my $res_headers = $c->tx->res->headers->to_hash;
		for (qw(Set-Cookie)) {
			delete $res_headers->{$_};
		}

		$log->{res} = {
			headers => $res_headers,
		};

		if($c->tx->res->code) {
			$log->{res}->{statusCode} = $c->tx->res->code;

			if($c->tx->res->code >= 400) {
				$log->{res}->{body} = $c->res->body;
			}
		}

		if ($features{'audit'}) {
			$log->{req}->{body} = $c->req->body;
			unless ($c->req->url =~ /login/) {
				$log->{res}->{body} = $c->res->body;
			}
		}

		if(my $e = $c->stash('exception')) {
			$c->stash('exception')->verbose;
			my $eframes = $c->stash('exception')->frames;

			my @frames;
			for my $frame (reverse $eframes->@*) {
				push @frames, {
					class => $frame->[0],
					file  => $frame->[1],
					line  => $frame->[2],
					func  => $frame->[3],
				}
			}

			$log->{err} = {
				fileName   => $frames[0]{file},
				lineNumber => $frames[0]{line},
				msg        => $c->stash('exception')->to_string,
				frames     => \@frames,
			};
		}

		my $l = Conch::Log->new(
			path  => $log_path,
			level => 'debug',
		);

		$l->request_id($c->req->request_id);
		$l->payload($log);
		$l->info();
	});
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
