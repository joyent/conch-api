=head1 NAME

Test::Conch::Datacenter

=head1 DESCRIPTION

Test::Conch, plus a "full datacenter" worth of test data and validation definitions.

For legacy tests only; use fixtures instead for new tests.

=head1 METHODS

=cut

package Test::Conch::Datacenter;

use Mojo::Base 'Test::Conch';

use Test::ConchTmpDB;
use Test::Conch;
use Path::Tiny;

=head2 new

	my $t = Test::Conch::Datacenter->new();
	$t->get_ok("/")->status_is(200)->json_schema_is("Whatever");

=cut

sub new {
    my $class = shift;
    my $args = @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {};

	# create a test database
	my $pg = Test::ConchTmpDB->mk_tmp_db;

	# load all sql files in sql/test
	Test::ConchTmpDB->schema($pg)->storage->dbh_do(sub {
		my ($storage, $dbh, @args) = @_;
		$dbh->do($_->slurp_utf8) or die "Failed to load sql file: $_"
			foreach sort (path('sql/test')->children(qr/\.sql$/));
	});

	my $self = Test::Conch->new(
		%$args,
		pg => $pg,
	);

	$self->load_validation_plans(
		[{
			name        => 'Conch v1 Legacy Plan: Server',
			description => 'Test Plan',
			validations => [ { name => 'product_name', version => 1 } ]
		}],
	);

	bless($self, $class);
	return $self;
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
