package Conch::Controller::Datacenters;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

Conch::Controller::Datacenters - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched Conch::Controller::Datacenters in Datacenters.');
}

sub list :Local {
  my ($self, $c) = @_;
  $c->stash(datacenters => [$c->model('DB::Datacenter')->all]);
  $c->stash(template => 'datacenters/list.tt2');
}

=encoding utf8

=head1 AUTHOR

Super-User

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
