package Conch::Plugin::Mail;

use v5.26;
use Mojo::Base 'Mojolicious::Plugin', -signatures;
use Conch::Mail;

=head1 NAME

Conch::Plugin::Mail - Sets up a helper to send emails

=head2 DESCRIPTION

Provides the helper sub 'send_mail' to the app and controllers:

	$c->send_mail('new_user_invite', {
		name => 'bob',
		email => 'bob@conch.joyent.us',
		password => 'whargarbl',
	});

=cut

sub register ($self, $app, $config) {
    $app->helper(send_mail => sub ($c, $template_name, @args) {

		Mojo::IOLoop->subprocess(
			sub {
				my $subprocess = shift;

				Conch::Mail->new(log => $c->log)->$template_name(@args);
			},
			sub {
				my ($subprocess, $err, @results) = @_;
				if ($err) {
					$c->log->warn($template_name . ' email errored: ' . $err);
				}
			},
		);
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
# vim: set ts=4 sts=4 sw=4 et :
