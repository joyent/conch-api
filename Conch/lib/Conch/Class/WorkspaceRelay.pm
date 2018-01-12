package Conch::Class::WorkspaceRelay;
use Mojo::Base -base, -signatures;
use Role::Tiny 'with';

with 'Conch::Class::Role::JsonV1';

has [qw(
  id
  alias
  created
  ipaddr
  ssh_port
  updated
  version
  devices
  location
  )];

sub as_v1_json {
  my $self = shift;
  {
    id => $self->id,
    alias => $self->alias,
    created => $self->created,
    ipaddr => $self->ipaddr,
    ssh_port => $self->ssh_port,
    updated => $self->updated,
    version => $self->version,
    devices => [ map { $_->as_v1_json } @{ $self->devices } ],
    location => $self->location
  }
}

1;



