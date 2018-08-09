package Conch::Role::Validation;

use Mojo::Base -role, -signatures;

use Try::Tiny;

use Conch::Pg;

use Mojo::Exception;
use Mojo::JSON;

use Conch::ValidationError;
use Conch::Log;

requires 'name';
requires 'description';
requires 'version';
requires 'category';

requires 'validate';


has 'log' => sub { Conch::Log->new() };

has 'validation_results' => sub { [] };

use constant {
	STATUS_ERROR => 'error',
	STATUS_FAIL  => 'fail',
	STATUS_PASS  => 'pass'
};


has 'hardware_product';
has 'device';
has 'device_location';
has 'device_settings';
has 'result_builder' => sub { sub {return {@_}} };


sub run ( $self, $data ) {
	try {
		$self->validate($data);
	}
	catch {
		my $err = $_;
		# FIXME wat
		if ( not $err->isa('Conch::ValidationError') ) {
			# remove the 'at $filename line $line_number' from the exception
			# message. We might not want to reveal Conch's path
			$err =~ s/ at .+$//;
			$err = Conch::ValidationError->new($err)->trace(1);
		}

		$self->log->error("Validation '".$self->name."' threw an exception: ".$err->message);
		$self->log->debug("Bad data: ". Mojo::JSON::to_json($data));


		my $validation_error = $self->result_builder->(
			message  => $err->message,
			name     => $self->name,
			status   => STATUS_ERROR,
			hint     => $err->hint || $err->error_loc,
			category => $self->category,
		);
		push $self->validation_results->@*, $validation_error;
	};
	return $self;
}

# FIXME REMOVE ALL OF THESE
sub hardware_product_name ($self) {
	$self->hardware_product->name;
}

sub hardware_legacy_product_name ($self) {
	$self->hardware_product->legacy_product_name;
}


sub hardware_product_generation ($self) {
	$self->hardware_product->generation_name;
}


sub hardware_product_sku ($self) {
	$self->hardware_product->sku;
}


sub hardware_product_specification ($self) {
	$self->hardware_product->specification;
}


sub hardware_product_vendor ($self) {
	$self->hardware_product->vendor;
}


sub hardware_product_profile ($self) {
	$self->hardware_product->profile;
}


sub register_result ( $self, %attrs ) {
	my $expected = $attrs{expected};
	my $got      = $attrs{got};
	my $cmp_op   = $attrs{cmp} || 'eq';

	$self->die( "'expected' value must be defined", level => 2 )
		unless defined($expected);

	return $self->fail("'got' value is undefined") unless defined($got);

	$self->die( "'got' value must be a scalar", level => 2 ) if ref($got);

	if ( $cmp_op eq 'oneOf' ) {
		$self->die( "'expected' value must be an array when comparing with 'oneOf'",
			level => 2 )
			unless ref($expected) eq 'ARRAY';
	}
	elsif ( $cmp_op eq 'like' ) {
		$self->die(
			"'expected' value must be a scalar or Regexp when comparing with 'like'",
			level => 2
		) unless ref($expected) eq 'Regexp' || ref($expected) eq '';
	}
	else {
		$self->die(
			"'expected' value must be a scalar when comparing with '$cmp_op'",
			level => 2 )
			if ref($expected);
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


sub die ( $self, $message, %args ) {
	die Conch::ValidationError->new($message)->hint( $args{hint} )
		->trace( $args{level} || 1 );
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
	$self->validation_results( [] );
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
