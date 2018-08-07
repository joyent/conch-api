package Test::Conch;

use v5.26;
use Mojo::Base 'Test::Mojo';

use Test::More ();
use Test::ConchTmpDB 'mk_tmp_db';
use Conch::UUID 'is_uuid';
use IO::All;
use JSON::Validator;

=pod

=head1 DESCRIPTION

Takes care of setting up a Test::Mojo with the Conch application pre-configured.

Includes JSON validation ability via L<Test::MojoSchema>.

    my $t = Test::Conch->new();
    $t->get_ok("/")->status_is(200)->json_schema_is("Whatever");

=head2 pg

Override with your own Test::PostgreSQL object if you want to use a custom database, perhaps
with extra settings or loaded with additional data.  Defaults to the basic database created by
L<Test::ConchTmpDB/mk_tmp_db>.

This is the attribute to copy if you want multiple Test::Conch objects to be able to talk to
the same database.

=cut

has 'pg';   # this is generally a Test::PostgreSQL object

=head2 schema

The Conch::Schema object, used for direct database access. Will (re)connect as needed.

=cut

has 'schema' => sub {
    my $self = shift;
    Test::ConchTmpDB->schema($self->pg);
};

=head2 validator

=cut

has 'validator' => sub {
    my $spec_file = "json-schema/response.yaml";
    die("OpenAPI spec file '$spec_file' doesn't exist.")
        unless io->file($spec_file)->exists;

    my $validator = JSON::Validator->new;
    $validator->schema($spec_file);

    # add UUID validation
    my $valid_formats = $validator->formats;
    $valid_formats->{uuid} = \&is_uuid;
    $validator->formats($valid_formats);
    $validator;
};

=head2 new

Constructor. Takes the following arguments:

  * pg (optional). uses this as the postgres db.

=cut

sub new {
    my $class = shift;
    my $args = @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {};

    my $pg = $args->{pg} // mk_tmp_db();
    $pg or Test::More::BAIL_OUT("failed to create test database");

    my $self = Test::Mojo->new(
        Conch => {
            pg      => $pg->uri,
            secrets => ["********"]
        }
    );

    bless($self, $class);
    $self->pg($pg);
    return $self;
}

=head2 json_schema_is

Adds a method 'json_schema_is` to validate the JSON response of
the most recent request. If given a string, looks up the schema in
#/definitions in the JSON Schema spec to validate. If given a hash, uses
the hash as the schema to validate.

=cut

sub json_schema_is {
    my ( $self, $schema ) = @_;

    my @errors;
    return $self->_test( 'fail', 'No request has been made' ) unless $self->tx;
    my $json = $self->tx->res->json;
    return $self->_test( 'fail', 'No JSON in response' ) unless $json;

    if ( ref $schema eq 'HASH' ) {
        @errors = $self->validator->validate( $json, $schema );
    }
    else {
        my $component_schema = $self->validator->get("/definitions/$schema");
        return $self->_test( 'fail',
            "Component schema '$schema' is not defined in JSON schema " )
            unless $component_schema;
        @errors = $self->validator->validate( $json, $component_schema );
    }

    my $error_count = @errors;
    my $req         = $self->tx->req->method . ' ' . $self->tx->req->url->path;
    return $self->_test( 'ok', !$error_count,
        'JSON response has no schema validation errors' )->or(
        sub {
            Test::More::diag( $error_count
                    . " Error(s) occurred when validating $req with schema "
                    . "$schema':\n\t"
                    . join( "\n\t", @errors ) );
            0;
        }
    );
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
