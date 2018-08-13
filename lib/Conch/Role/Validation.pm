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
	return Conch::DB->connect(
		$db->dsn,
		$db->username,
		$db->password,
		{ ReadOnly => 1 },
	);
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
);

sub _build_validation_results {
	return []
}

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
);

sub _build_result_builder {
	return sub {return {@_}};
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

sub register_result ( $self, %attrs ) {
	my $expected = $attrs{expected};
	my $got      = $attrs{got};
	my $cmp_op   = $attrs{cmp} || 'eq';

	$self->die( "'expected' value must be defined")
		unless defined($expected);

	return $self->fail("'got' value is undefined") unless defined($got);

	$self->die( "'got' value must be a scalar" ) if ref($got);

	if ( $cmp_op eq 'oneOf' ) {
		$self->die( "'expected' value must be an array when comparing with 'oneOf'")
			unless ref($expected) eq 'ARRAY';
	}
	elsif ( $cmp_op eq 'like' ) {
		$self->die(
			"'expected' value must be a scalar or Regexp when comparing with 'like'",
		) unless ref($expected) eq 'Regexp' || ref($expected) eq '';
	}
	else {
		$self->die(
			"'expected' value must be a scalar when comparing with '$cmp_op'"
		) if ref($expected);
	}

	my $cmp_dispatch = {
		'=='  => sub { $_[0] == $_[1] },
		'!='  => sub { $_[0] != $_[1] },
		'>'   => sub { $_[0] > $_[1] },
		'>='  => sub { $_[0] >= $_[1] },
		'<'   => sub { $_[0] < $_[1] },
		'<='  => sub { $_[0] <= $_[1] },
		'<='  => sub { $_[0] <= $_[1] },
		eq    => sub { $_[0] eq $_[1] },
		ne    => sub { $_[0] ne $_[1] },
		lt    => sub { $_[0] lt $_[1] },
		le    => sub { $_[0] le $_[1] },
		gt    => sub { $_[0] gt $_[1] },
		ge    => sub { $_[0] ge $_[1] },
		like  => sub { $_[0] =~ /$_[1]/ },
		oneOf => sub {
			scalar( grep { $_[0] eq $_ } $_[1]->@* );
		}
	};

	my $success = $cmp_dispatch->{$cmp_op}->( $got, $expected );
	my $message;
	if ( $cmp_op eq 'oneOf' ) {
		$message =
			  'Expected one of: '
			. join( ', ', map { "'$_'" } $expected->@* )
			. ". Got '$got'.";
	}

	# For relational operators, we want to produce messages that do not change
	# between validation executions as long as the relation is constant.
	elsif ( grep /$cmp_op/, ( '>', '>=', '<', '<=', 'lt', 'le', 'gt', 'ge' ) ) {
		$message = "Expected a value $cmp_op '$expected'.";
		$message .= $success ? ' Passed.' : ' Failed.';
	}
	else {
		$message = "Expected $cmp_op '$expected'. Got '$got'.";
	}

	my $validation_result = $self->result_builder->(
		message  => $attrs{message}  || $message,
		name     => $attrs{name}     || $self->name,
		category => $attrs{category} || $self->category,
		component_id => $attrs{component_id},
		status       => $success ? STATUS_PASS : STATUS_FAIL,
		hint         => $success ? $attrs{hint} : undef
	);

	$self->log->debug(join('',
		"Validation ",
		$validation_result->{name} // "'unknown'",
		" had result ",
		$validation_result->{status},
		": ",
		$validation_result->{message}
	));

	push $self->validation_results->@*, $validation_result;
	return $self;

}


sub die ( $self, $message ) {
	Mojo::Exception->throw($message);
}


sub fail ( $self, $message, %attrs ) {
	my $validation_result = $self->result_builder->(
		message      => $message,
		name         => $attrs{name} || $self->name,
		category     => $attrs{category} || $self->category,
		component_id => $attrs{component_id},
		status       => STATUS_FAIL,
		hint         => $attrs{hint}
	);
	push $self->validation_results->@*, $validation_result;
	return $self;
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
