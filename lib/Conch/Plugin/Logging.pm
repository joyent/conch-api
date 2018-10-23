package Conch::Plugin::Logging;

use Mojo::Base 'Mojolicious::Plugin', -signatures;
use Conch::Log;
use Sys::Hostname;
use Mojo::File 'path';

=pod

=head1 NAME

Conch::Plugin::Logging - Sets up logging for the application

=head1 METHODS

=head2 register

Initializes the logger object, and sets up hooks in various places to log request data and
process exceptions.

=cut

sub register ($self, $app, $config) {

	my $log_dir = $config->{log_dir} // 'log';

	my %log_args = (
		level => 'debug',
	);

	# without 'path' option, Mojo::Log defaults to *STDERR
	if(not $app->feature('log_to_stderr')) {
		$log_dir = path($log_dir);
		$log_dir = $app->home->child($log_dir) if not $log_dir->is_abs;

		if (-d $log_dir) {
			return Mojo::Exception->throw("Cannot write to $log_dir") if not -w $log_dir;
		} else {
			print STDERR "Creating log dir $log_dir\n";
			$log_dir->dirname->make_path($log_dir);
		}

		$log_args{path} = $log_dir->child($app->mode . '.log');
	}

	$app->log(Conch::Log->new(%log_args));

	if ($app->feature('rollbar')) {
		$app->hook(
			before_render => sub ($c, $args) {
				my $template = $args->{template};

				if (my $exception = $c->stash('exception')
						or ($template and $template =~ /exception/)) {
					$exception //= $args->{exception};
					$exception->verbose(1);
					$c->send_exception_to_rollbar($exception);
				}
			}
		);
	}

	$app->hook(after_dispatch => sub ($c) {

		my $u_str = $c->stash('user') ?
			$c->stash('user')->email . " (".$c->stash('user')->id.")" :
			'NOT AUTHED';

		my $req_headers = $c->tx->req->headers->to_hash(1);
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

		my $res_headers = $c->tx->res->headers->to_hash(1);
		for (qw(Set-Cookie)) {
			delete $res_headers->{$_};
		}

		$log->{res} = {
			headers => $res_headers,
		};

		if ($c->res->code) {
			$log->{res}{statusCode} = $c->res->code;
			$log->{res}{body} = $c->res->text if $c->res->code >= 400;
		}

		if ($c->feature('audit')) {
			$log->{req}{body} = $c->req->text;
			$log->{res}{body} //= $c->res->text if $c->req->url !~ /login/;
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

		my $l = Conch::Log->new(%log_args);

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
