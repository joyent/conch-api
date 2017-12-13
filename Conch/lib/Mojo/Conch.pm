package Mojo::Conch;
use Mojo::Base 'Mojolicious';

use Mojo::Conch::Route qw(all_routes);
use Mojo::Pg;
use Mojolicious::Plugin::Bcrypt;
use Data::Printer;


sub startup {
  my $self = shift;
  my $r = $self->routes;

   # Configuration
  $self->plugin('Config');
  $self->secrets($self->config('secrets'));
  $self->sessions->cookie_name('conch');
  $self->sessions->default_expiration(2592000); # 30 days

  my $pg_uri = $self->config('pg');
  $self->helper(pg => sub {
      state $pg = Mojo::Pg->new($pg_uri);
    });

  $self->helper(status => sub {
      my $self = shift;
      $self->res->code(shift);
      my $payload = shift;
      return $payload ?  $self->render(json => $payload) : $self->finish;
    });

  # Render exceptions and Not Found as JSON
  $self->hook(before_render => sub {
      my ($c, $args) = @_;
      return unless my $template = $args->{template};
      if ($template =~ /exception/) {
        my $exception = $args->{exception};
        $exception->verbose(1);
        $self->log->error( $exception );
        my @stack = @{$exception->frames};
        @stack = map { "\t" . $_->[3] . ' at ' . $_->[1] . ':' . $_->[2] }
          @{$exception->frames}[0..10];
        $self->log->error("Stack Trace (first 10 frames):\n" . join("\n", @stack) );
        return $args->{json} = { error => 'Something went wrong' };
      }
      if ($args->{template} =~ /not_found/) {
        return $args->{json} = { error => 'Not Found' };
      }
    });

  # use cost 4 for backwards compatibility with passwords hashed with
  # Dancer2::Plugin::Passphrase
  $self->plugin('bcrypt', { cost => 4 });
  $self->plugin('Util::RandomString');
  $self->plugin('Mojo::Conch::Plugin::Model');
  $self->plugin('Mojo::Conch::Plugin::Mail');

  all_routes($r);
}

1;
