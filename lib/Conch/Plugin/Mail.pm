package Conch::Plugin::Mail;

use v5.26;
use warnings;
use Mojo::Base 'Mojolicious::Plugin', -signatures;

use Email::Simple;
use Email::Sender::Simple 'sendmail';
use Email::Sender::Transport::SMTP;

=pod

=head1 NAME

Conch::Plugin::Mail - Sets up a helper to send emails

=head2 DESCRIPTION

Provides the helper sub 'send_mail' to the app and controllers:

    $c->send_mail(
        template_file => $filename, # file in templates/email, without extension
            OR
        template => $template_string,
            OR
        content => $raw_content,

        to => $to_email,        defaults to stashed 'target_user'
        from => $from_email,    defaults to stashed 'user'
        subject => $subject,

        ... all additional arguments are passed to the template renderer ...
    );

=cut

sub register ($self, $app, $config) {
    $app->helper(send_mail => sub ($c, %args) {
        state sub compose_message ($c, %args) {
            # see Mojolicious::Guides::Rendering, Mojo::Template
            my $content = $args{content} // $c->render_to_string(
                $args{template_file}
                    ? (template => 'email/'.$args{template_file})
                    : (inline => $args{template} // 'missing template'),
                format => 'txt',    # handler defaults to 'ep'
                %args,
            );

            state sub address ($user) {
                my $name = $user->name;
                my $email = $user->email;
                return $name eq $email
                    ? $email
                    : '"'.$name.'" <'.$email.'>';
            }

            my $to = $args{To} // address($c->stash('target_user'));
            my $from = $args{From} // address($c->stash('user'));
            my $subject = $args{Subject} // 'Important email from Conch';

            return Email::Simple->create(
                header => [
                    To => $to,
                    From => $from,
                    Subject => $subject,
                ],
                body => $content,
            );
        }

        my $email = compose_message($c, %args);
        my $log = $c->can('log') ? $c->log : $c->app->log;

        Mojo::IOLoop->subprocess(
            # called in the context of the child process; returns the email object that was
            # sent for delivery
            sub ($subprocess) {
                $log->info('sending email "'
                    .($args{template_file} // substr(0,20,$args{template} // $args{content}).'...')
                    .'" to '.$email->header('to'));

                my $result = Email::Sender::Simple->send($email, {
                    transport => Email::Sender::Transport::SMTP->new($config->{mail}{transport} // {}),
                });

                return $result, $email;
            },

            # called in the context of the parent process on completion
            sub ($subprocess, $err, @args) {
                if ($err) {
                    $log->warn('sending email errored: '.$err);
                    return;
                }

                my ($result, $email) = @args;

                # this is typically the receipt response from sendmail
                $log->debug('sent email: '.$result->{message}) if $result->{message};
            },
        );

        # the only listener here is in our test infrastructure
        $c->app->plugins->emit(mail_composed => $email);
    });
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
