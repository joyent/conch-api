package Conch::Class::DeviceDetailed;
use Mojo::Base -base, -signatures;
use Role::Tiny 'with';

with 'Conch::Class::Role::JsonV1';

has [
	qw(
		device
		latest_report
		validation_results
		nics
		location
		)
];

sub as_v1_json {
	my $self    = shift;
	my $device  = $self->device->as_v1;
	my @results = map { $_->{validation} } $self->validation_results->@*;

	my $details = {
		latest_report => $self->latest_report,
		validations   => \@results,
		nics          => $self->nics,
		location      => $self->location && $self->location->as_v1_json
	};
	return { %$device, %$details };
}

1;
