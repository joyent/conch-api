package Conch::Class::WorkspaceRelay;
use Mojo::Base -base, -signatures;
use Role::Tiny 'with';

with 'Conch::Class::Role::JsonV2';

has [qw(
  id
  alias
  created
  id
  ipaddr
  ssh_port
  updated
  version
  devices
  location
  )];

sub as_v2_json {
  my $self = shift;
  {
    id => $self->id,
    alias => $self->alias,
    created => $self->created,
    ipaddr => $self->ipaddr,
    ssh_port => $self->ssh_port,
    updated => $self->updated,
    version => $self->version,
    devices => [ map { $_->as_v2_json } @$self->devices ],
    devices => $self->location
  }
}

1;



