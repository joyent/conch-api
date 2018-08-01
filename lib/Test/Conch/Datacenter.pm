=head1 NAME

Test::Conch::Datacenter

=head1 DESCRIPTION

Does all the work to standup a test db, test harness, and all the other magic
necessary to test against a full datacenter worth of test data.

Includes JSON validation ability via L<Test::MojoSchema>

=head1 METHODS

=cut

package Test::Conch::Datacenter;

use Mojo::Base 'Test::Conch';

use Test::ConchTmpDB;
use Conch::Models;

use Conch::Log;


=head2 new

	my $t = Test::Conch::Datacenter->new();
	$t->get_ok("/")->status_is(200)->json_schema_is("Whatever");

=cut

sub new {
    my $class = shift;
    my $args = @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {};

	my $self = Test::Conch->new(
		%$args,
		pg => Test::ConchTmpDB->make_full_db,
	);

	Conch::ValidationSystem->load_validation_plans(
		[{
			name        => 'Conch v1 Legacy Plan: Server',
			description => 'Test Plan',
			validations => [ { name => 'product_name', version => 1 } ]
		}],
		Conch::Log->new(level => 'fatal'),
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
