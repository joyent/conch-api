=head1 NAME

Test::Conch::Datacenter

=head1 DESCRIPTION

Does all the work to standup a test db, test harness, and all the other magic
necessary to test against a full datacenter worth of test data.

Includes JSON validation ability via L<Test::MojoSchema>

=head1 METHODS

=cut

package Test::Conch::Datacenter;

use Mojo::Base -strict;
use Test::MojoSchema;
use Data::UUID;
use Conch::UUID 'is_uuid';
use IO::All;
use JSON::Validator;

use Test::ConchTmpDB;
use Conch::Models;
use Conch::Route qw(all_routes);


=head2 initialize

	my ($pg, $t) = Test::Conch::Datacenter->initialize();
	$t->get_ok("/")->status_is(200)->json_schema_is("Whatever");

=cut

sub initialize {
	my $spec_file = "json-schema/response.yaml";
	die("OpenAPI spec file '$spec_file' doesn't exist.")
		unless io->file($spec_file)->exists;

	my $validator = JSON::Validator->new;
	$validator->schema($spec_file);

	# add UUID validation
	my $valid_formats = $validator->formats;
	$valid_formats->{uuid} = \&is_uuid;
	$validator->formats($valid_formats);


	my $pgtmp = Test::ConchTmpDB->make_full_db
		or die("failed to create test database");

	my $dbh = DBI->connect( $pgtmp->dsn );

	my $t = Test::MojoSchema->new(
		Conch => {
			pg      => $pgtmp->uri,
			secrets => ["********"],
		},
	);

	Conch::ValidationSystem->load_validation_plans([
		{
			name        => 'Conch v1 Legacy Plan: Server',
			description => 'Test Plan',
			validations => [ { name => 'product_name', version => 1 } ]
		}
	]);

	$t->validator($validator);

	all_routes( $t->app->routes );

	return ($pgtmp, $t);
}

1;

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.

=cut
