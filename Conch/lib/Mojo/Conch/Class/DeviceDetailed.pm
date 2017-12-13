package Mojo::Conch::Class::DeviceDetailed;
use Mojo::Base -base, -signatures;
use Role::Tiny 'with';

with 'Mojo::Conch::Class::Role::JsonV2';

has [qw(
    device
    latest_report
    validation_results
    nics
    location
  )];

sub as_v2_json {
  my $self = shift;
  my $device = $self->device->as_v2_json;
  my $details =
    {
      latest_report => $self->latest_report,
      validations => $self->validation_results,
      nics => $self->nics,
      location => $self->location && $self->location->as_v2_json
    };
  return { %$device, %$details };
}

1;
