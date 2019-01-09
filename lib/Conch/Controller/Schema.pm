package Conch::Controller::Schema;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Data::Visitor::Tiny qw(visit);
use Conch::Plugin::JsonValidator;
use Mojo::Util qw(camelize);

=pod

=head1 NAME

Conch::Controller::Schema

=head1 METHODS

=head2 get

Get the json-schema in JSON format.

=cut

sub get ($c) {
	my $type = $c->stash('request_or_response');
	my $name = camelize $c->stash('name');

	my $validator = JSON::Validator->new();

	if ( lc($type) eq 'response' ) {
		$validator->schema(Conch::Plugin::JsonValidator::OUTPUT_SCHEMA_FILE);

	}
	elsif ( lc($type) eq 'request' ) {
		$validator->schema(Conch::Plugin::JsonValidator::INPUT_SCHEMA_FILE);
	}

	my $schema = $validator->get("/definitions/$name");

	my sub inline_ref ( $ref, $schema ) {
		my ($other) = $ref =~ m|#?/definitions/(\w+)$|;
		$schema->{definitions}{$other} = $validator->get($ref);
	}

	visit $schema => sub ( $key, $ref, @ ) {
		inline_ref( $_ => $schema ) if $key eq '$ref';
		if ( !defined $_ && $key eq "type" ) {
			$$ref = "null";
		}
	};
	$schema->{title} //= $name;
	$schema->{'$schema'} = 'http://json-schema.org/draft-07/schema#';
	$schema->{'$id'}     = "urn:$name.schema.json";

	return $c->status( 200, $schema );
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
