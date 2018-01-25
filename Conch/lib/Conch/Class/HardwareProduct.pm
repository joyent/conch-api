package Conch::Class::HardwareProduct;
use Mojo::Base -base, -signatures;
use Role::Tiny 'with';

with 'Conch::Class::Role::JsonV1';

has [
	qw(
		id
		name
		alias
		prefix
		vendor
		profile
		)
];

sub as_v1_json {
	my $self = shift;
	{
		id      => $self->id,
		name    => $self->name,
		alias   => $self->alias,
		prefix  => $self->prefix,
		vendor  => $self->vendor,
		profile => $self->profile && $self->profile->as_v1_json
	};
}

1;
