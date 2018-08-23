=head1 NAME

Conch::Role::Validation

=head1 DESCRIPTION

A Moo role for implementing a Validation interface

=head1 SYNOPSIS

	use Role::Tiny::With;
	with 'Conch::Role::Validation';

	use constant {
		name        => '',
		category    => 'WAT',
		description => '',
		version     => 1,
	};

	sub validate {
		my ($self, $data) = @_;
	}

=head1 REQUIREMENTS

=cut

package Conch::Role::Validation;

use strict;
use warnings;
use utf8;
use v5.20;

use Moo::Role;
use experimental qw(signatures);
use Type::Tiny;
use Types::Standard qw(InstanceOf ArrayRef HashRef CodeRef);

use Try::Tiny;

use Conch::DB;

use Mojo::Exception;
use Mojo::JSON;

use Conch::Log;

use constant {
	STATUS_ERROR => 'error',
	STATUS_FAIL  => 'fail',
	STATUS_PASS  => 'pass'
};

requires 'name';
requires 'description';
requires 'version';
requires 'category';

requires 'validate';



has 'db' => (
	is => 'lazy',
);

sub _build_db {
	my $db = Conch::Pg->new();
	return Conch::DB->connect(sub {
		DBI->connect(
			$db->dsn,
			$db->username,
			$db->password,
			{
				ReadOnly			=> 1,
				AutoCommit			=> 0,
				AutoInactiveDestroy => 1,
				PrintError          => 0,
				PrintWarn           => 0,
				RaiseError          => 1,
			});
	});
}


has 'log' => (
	is      => 'rw',
	isa     => InstanceOf['Mojo::Log'],
	default => sub { Conch::Log->new() }
);

has 'validation_results' => (
	clearer => 1,
	is => 'lazy',
	isa => ArrayRef[InstanceOf['Conch::Model::ValidationResults']],
	default => sub { [] },
);

has 'device' => ( 
	is => 'rw',
	isa => InstanceOf["Conch::Model::Device"], # FIXME switch to DBIC
);

has 'hardware_product' => ( #FIXME replace with DBIC lookup off ->device
	is => 'rw',
	isa => InstanceOf['Conch::Class::HardwareProduct'], 
);

has 'device_settings' => ( # FIXME replace with DBIC lookup off -> device
	is => 'rw',
	isa => HashRef,
	default => sub { {} },
);


has 'result_builder' => ( # FIXME remove
	is => 'lazy',
	isa => CodeRef,
	default => sub { sub {return {@_}} },
);

has 'model' => (
	is => 'lazy'
);
sub _build_model {
	my $self = shift;
	return Conch::Model::Validation->lookup_by_name_and_version(
		$self->name,
		$self->version
	);
}

sub run ( $self, $data ) {
	try {
		Mojo::Exception->throw("Need a device") unless $self->device;
		$self->validate($data);
	}
	catch {
		my $err = $_;

		my $hint = "Exception raised";
		my $msg = 'Unknown';

		if($err->isa("Mojo::Exception")) {
			$hint = "Exception raised in '".
				$err->frames->[0]->[0].
				"' at line ".
				$err->frames->[0]->[2];

			$msg = $err->message;
		} elsif($err->isa("DBIx::Class::Exception")) {
			$msg = "$err";
		} else {
			chomp $err;
			$msg = $err;
		}

		$self->log->error(
			"Validation exception: ".
			$self->name.
			" - $hint - $msg"
		);

		$self->log->debug("Bad data: ". Mojo::JSON::to_json($data));

		my $validation_error = $self->result_builder->(
			message  => $msg,
			name     => $self->name,
			status   => STATUS_ERROR,
			hint     => $hint,
			category => $self->category,
		);
		push $self->validation_results->@*, $validation_error;
	};
	return $self;
}


use Test2::API qw/intercept/;
use Test2::Tools::ClassicCompare qw();
sub cmp_ok {
	my $self = shift;
	my @args = @_;
	my %extra = $args[4] ? $args[4]->@* : ();

	my $events = intercept {
		Test2::Tools::ClassicCompare::cmp_ok(
			$args[0],
			$args[1],
			$args[2],
			$args[3] // $self->name,
		);
	};

	my $e = shift $events->@*;

	my $message;
	if ($e->pass) {
		$message = "Expected $args[1] '$args[0]'. Got '$args[2]'. Success.";
	} else {
		$message = "Expected a value $args[1] '$args[0]'. Got '$args[2]'. Failed.";
	}

	$self->_record_result($e, $message, %extra);

	return $e->pass;
}

sub _record_result ($self, $event, $message, %attrs) {
	my $validation_result = $self->result_builder->(
		message  => $message,
		name     => $self->name,
		category => $attrs{category} || $self->category,
		component_id => $attrs{component_id},
		status       => $event->pass ? STATUS_PASS : STATUS_FAIL,
		hint         => $event->pass ? $attrs{hint} : undef
	);

	$self->log->debug(join('',
		"Validation ",
		$self->name,
		" had result ",
		$validation_result->{status},
		": ",
		$validation_result->{message}
	));

	push $self->validation_results->@*, $validation_result;
}




sub die ( $self, $message ) {
	Mojo::Exception->throw($message);
}


sub failures ( $self ) {
	[ grep { $_->{status} eq STATUS_FAIL } $self->validation_results->@* ];
}


sub successes ( $self ) {
	[ grep { $_->{status} eq STATUS_PASS } $self->validation_results->@* ];
}


sub error ( $self ) {
	[ grep { $_->{status} eq STATUS_ERROR } $self->validation_results->@* ];
}


sub clear_results ( $self ) {
	$self->clear_validation_results();
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
