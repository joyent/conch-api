package Test2::Conch::Validations;
use strict;
use warnings;
use feature ':5.20';

use base qw(Class::StrongSingleton);

use Conch::Log;
use Conch::Models;

use Test::ConchTmpDB;

sub new {
	my $class = shift;
	my $db = Test::ConchTmpDB->make_full_db;
	Conch::Pg->new( $db->uri );

	my $self = bless { db => $db }, $class;
	$self->_init_StrongSingleton();
	return $self;
}

use Test2::V0 qw();
use Test2::Tools::Exception;

sub test {
	my ($self, $validation, $device, $args) = @_;
	my $results = $validation->model->run_validation_for_device($device, $args);
	for ($results->@*) {
		if (
			($_->status eq $_->STATUS_FAIL) ||
			($_->status eq $_->STATUS_ERROR)
		) {
			die $_->message . " - " . ($_->hint // "");
		}
	}
}


sub done {
	my $self = shift;
	Test2::V0::done_testing;
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
