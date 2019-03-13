package Conch::Plugin::JsonValidator;

use Mojo::Base 'Mojolicious::Plugin', -signatures;

use JSON::Validator;

use constant OUTPUT_SCHEMA_FILE => "json-schema/response.yaml";
use constant INPUT_SCHEMA_FILE => "json-schema/input.yaml";

=pod

=head1 NAME

Conch::Plugin::JsonValidator

=head1 SYNOPSIS

    app->plugin('Conch::Plugin::JsonValidator');

    [ ... in a controller ]

    sub endpoint ($c) {
        my $body = $c->validate_input("MyInputDefinition");

        [ ... ]

        $c->status_with_validation(200, MyOutputDefinition => $ret);
    }

=head1 DESCRIPTION

Conch::Plugin::JsonValidator provides an optional manner to validate input and
output from a Mojo controller against JSON Schema.

The C<validate_input> helper uses the provided schema definition to validate
B<JUST> the incoming JSON request. Headers and query parameters B<ARE NOT>
validated. If the data fails validation, a 400 status is returned to user
with an error payload containing the validation errors.

The C<status_with_validation> helper validates the outgoing data against the
provided schema definition. If the data validates, C<status> is called, using
the provided status code and data. If the data validation fails, a
C<Mojo::Exception> is thrown, returning a 500 to the user.

=head1 SCHEMAS

C<validate_input> validates data against the C<json-schema/input.yaml> file.

=head1 HELPERS

=cut

sub register ($self, $app, $config) {


=head2 validate_input

Given a json schema name validate the provided input against it, and prepare a HTTP 400
response if validation failed; returns validated input on success.

=cut

    $app->helper(validate_input => sub ($c, $schema_name, $input = $c->req->json) {
        my $validator = JSON::Validator->new;
        $validator->load_and_validate_schema(INPUT_SCHEMA_FILE, { schema => 'http://json-schema.org/draft-07/schema#' });

        my $schema = $validator->get('/definitions/'.$schema_name);

        if (not $schema) {
            Mojo::Exception->throw("unable to locate schema $schema");
            return;
        }

        if (my @errors = $validator->validate($input, $schema)) {
            $c->log->error("FAILED data validation for schema $schema_name".join(' // ', @errors));
            return $c->status(400 => { error => join("\n",@errors) });
        }

        $c->log->debug("Passed data validation for input schema $schema_name");
        return $input;
    });


=head2 get_input_validator

Returns a JSON::Validator object suitable for validating an endpoint input.

=cut

    $app->helper(get_input_validator => sub ($c) {
        my $validator = JSON::Validator->new;
        # FIXME: JSON::Validator should be picking this up out of the schema on its own.
        $validator->load_and_validate_schema(INPUT_SCHEMA_FILE, { schema => 'http://json-schema.org/draft-07/schema#' });
        return $validator;
    });


=head2 get_response_validator

Returns a JSON::Validator object suitable for validating an endpoint response.

=cut

    $app->helper(get_response_validator => sub ($c) {
        my $validator = JSON::Validator->new;
        # FIXME: JSON::Validator should be picking this up out of the schema on its own.
        $validator->load_and_validate_schema(OUTPUT_SCHEMA_FILE, { schema => 'http://json-schema.org/draft-07/schema#' });
        return $validator;
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
