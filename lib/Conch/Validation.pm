=pod

=head1 NAME

Conch::Validation - base class for writing Conch Validations

=head1 SYNOPSIS

    package Conch::Validation::DeviceValidation;
    # either:
        use Mojo::Base 'Conch::Validation';
    # or, if you want to use Moo features:
        use Moo;
        use strictures 2;
        extends 'Conch::Validation';

    use constant name        => 'device_validation';
    use constant version     => 1;
    use constant category    => 'CPU';
    use constant description => q/Description of the validation/;

    sub validate {
        my ($self, $input_data) = @_;

        my $device           = $self->device;
        my $device_settings  = $self->device_settings;
        my $device_location  = $self->device_location;
        my $hardware_vendor  = $self->hardware_product_vendor;
        my $hardware_name    = $self->hardware_product_name;

        $self->register_result(expected => 'hello', got => $input_data->{hello});
    }


=head1 DESCRIPTION

L<Conch::Validation> provides the base class to define and execute Conch
Validations. Validations extend this class by implementing a L</validate>
method.  This method receives the input data (a C<HASHREF>) to be validated.

The validation logic in the L</validate> method will evaluate the input data and
register one or more validation results with the
L</register_result> method. The logic may use device, device
settings, hardware product name, hardware product vendor, and other
details to dispatch conditions and evaluation.

Conch Validations should also define values for the C<name>, C<version>,
C<category>, and C<description> attributes. These attributes are used in the
identification of the validation and validation result storage in the
Validation System infrastructure.

Testing Conch Validations should be done with
L<Test::Conch::Validation/test_validation> with TAP-based tests. This
functions tests that Validations define the required attributes and methods,
and allow you to test the validation logic by running test cases against
expected results.

=cut

package Conch::Validation;

use Moo;
no Moo::sification;
use strictures 2;
use experimental 'signatures';
use Types::Standard qw(Str ArrayRef HashRef InstanceOf);
use Try::Tiny;
use Conch::ValidationError;
use Path::Tiny;
use List::Util 'first';
use MooX::HandlesVia;
use namespace::clean;

=head1 CONSTANTS

=head2 name

The validator name, provided by the validator module.

=head2 version

The validator version, provided by the validator module.

=head2 description

The validator description, provided by the validator module.

=head2 category

The validator category, provided by the validator module.

=cut

sub name { die 'name required' }
sub version { die 'version required' }
sub description { die 'description required' }
sub category ($self) { die ref($self) || $self, ' does not set a category' }

use constant {
    _STATUS_ERROR => 'error',
    _STATUS_FAIL  => 'fail',
    _STATUS_PASS  => 'pass'
};

=head1 METHODS

=head2 log

A logging object.

=cut

has log => (
    is => 'ro',
    isa => InstanceOf['Mojo::Log'],
    required => 1,
);

=head2 device

L<Conch::DB::Result::Device> object under validation.  Use in validation
logic to dispatch on Device attributes.

    my $device = $self->device;
    if ($device->asset_tag eq '...') {...}

Any additional data related to devices may be read as normal using L<DBIx::Class> interfaces.
The result object is built using a read-only database handle, so attempts to alter the data
will B<not> be permitted.

=cut

has device => (
    is => 'ro',
    isa => InstanceOf['Conch::DB::Result::Device'],
    required => 1,
);

=head2 device_location

L<Conch::DB::Result::DeviceLocation> object for the device being validated.

This is useful in writing validation logic that may depend on the rack or
location in the rack a device occupies.

    my $datacenter_name = $self->device_location->rack->datacenter->name;
    my $rack_unit_start = $self->device_location->rack_unit_start;

=cut

sub device_location ($self) {
    my $location = $self->device->device_location;
    $self->die(
        "Device must be assigned a location.",
        hint  => "Assign this device to a rack slot before running this validation",
        level => 2
    ) unless $location;
    return $location;
}

=head2 has_device_location

Returns a boolean whether the device under validation has been assigned a
location.

=cut

sub has_device_location ($self) {
    $self->device->device_location ? 1 : 0
}

=head2 hardware_product

The L<Conch::DB::Result::HardwareProduct> object for the device being validated
(originally determined by the sku reported for the device).

Any additional data related to hardware_products may be read as normal using L<DBIx::Class>
interfaces.  The result object is built using a read-only database handle, so attempts to alter
the data will B<not> be permitted.

=head2 hardware_product_name

Get the expected hardware product name for the device under validation.

    if ($self->hardware_product_name eq 'Joyent-123') {...}

=head2 hardware_legacy_product_name

Get the expected hardware legacy product name for the device under validation.

    if ($self->hardware_legacy_product_name eq 'Joyent-123') {...}

=head2 hardware_product_generation

Get the expected hardware product generation for the device under validation.

    if ($self->hardware_product_generation eq 'Joyent-123') {...}

=head2 hardware_product_sku

Get the expected hardware product SKU for the device under validation.

    if ($self->hardware_product_sku eq 'Joyent-123') {...}

=head2 hardware_product_specification

Get the expected hardware product specification for the device under
validation. Returns a JSON string (for now).

=head2 hardware_product_vendor

Get the expected hardware product vendor name for the device under validation.

    if ($self->hardware_product_vendor eq 'Dell') {...}

=cut

has hardware_product => (
    is => 'ro',
    init_arg => undef,  # cannot be provided at construction time
    isa => InstanceOf['Conch::DB::Result::HardwareProduct'],
    lazy => 1,
    default => sub ($self) {
        $self->device->hardware_product;
    },
    handles => {
        hardware_product_name => 'name',
        hardware_legacy_product_name => 'legacy_product_name',
        hardware_product_generation => 'generation_name',
        hardware_product_sku => 'sku',
        hardware_product_specification => 'specification',
        hardware_product_vendor => 'hardware_vendor',
    },
);

=head2 device_settings

A key-value unblessed hashref of device settings stored for the device being validated.

=cut

has device_settings => (
    is => 'ro',
    init_arg => undef,  # cannot be provided at construction time
    isa => HashRef[Str],
    lazy => 1,
    default => sub ($self) {
        my $device = $self->device;
        return +{} if not $device;
        +{ $device->self_rs->device_settings_as_hash };
    },
);

=head2 validation_results

Get the list of all validation results.

=head2 validation_result

Get a validation result by (0-based) index.

=head2 failures

Get the list of validation results that were failures

=head2 successes

Get the list of validation results that were successful

=head2 error

Get the list of validation results that have error status (halted execution).

I<NOTE:> Unless L</run> is called multiple times on the same validation object
without calling L</clear_results> between, there should be at most 1 error
validation because execution is halted.

=head2 clear_results

Clear the stored validation results.

=cut

has _validation_results => (
    is => 'bare',
    init_arg => undef,  # cannot be provided at construction time
    isa => ArrayRef[HashRef[Str]],
    lazy => 1,
    default => sub { [] },
    handles_via => 'Array',
    handles => {
        validation_results => 'elements',
        validation_result => 'get',
        _push_validation_result => 'push',
        failures => [ grep => sub { $_->{status} eq _STATUS_FAIL } ],
        successes => [ grep => sub { $_->{status} eq _STATUS_PASS } ],
        error => [ grep => sub { $_->{status} eq _STATUS_ERROR } ],
        clear_results => 'clear',
    },
);

=head2 run

Run the Validation with the specified input data.

    $validation->run($validation_data);

=cut

sub run ($self, $data) {
    try {
        $self->validate($data);
    }
    catch {
        my $err = $_;

        my ($message, $hint);
        if ($err->isa('Conch::ValidationError')) {
            $message = $err->message;
            $hint = $err->hint || $err->error_loc;
        }
        # remove the 'at $filename line $line_number' from the exception
        # message. We might not want to reveal Conch's path
        else {
            ($message) = $err =~ /\A(.+) at /ms;
            $hint = first { path($_)->is_relative }
                map s/\A.+ at (.+ line \d+)\.?\Z/$1/msr, split /\R/, $err;
        }

        $self->log->error("Validation '".$self->name.'\' threw an exception on device id \''
            .$self->device->id.'\': '.($message // $err));

        my $validation_error = {
            message  => $message // $err,
            name     => $self->name,
            status   => _STATUS_ERROR,
            hint     => $hint,
            category => $self->category,
        };
        $self->_push_validation_result($validation_error);
    };
    return $self;
}

=head2 validate

Contains the validation logic for validations.

This method must be re-defined in sub-classes of L<Conch::Validation> or it will
raise an exception.

    package MyValidation;
    use Mojo::Base 'Conch::Validation';

    sub validate {
        my ($self, $data) = @_;
        $self->register_result({ expected => 1, got => $data->{pass} });
    }

=cut

sub validate ($self, $data) {
    $self->die('Validations must implement the `validate` method in subclass!',
        level => 2);
}

=head2 register_result

Register a Validation Result in the validation logic. L</register_result> may be
called as many times as desired in a L</validate> method.

Instead of calculating whether a result should pass or fail in the validation
logic, provide an 'expected' value, the 'got' value, and a comparison operator.
This declarative syntax allows for result deduplication and consistent messages.


    # direct comparison
    $self->register_result(expected => 'hello', got => 'hello');
    $self->register_result(expected => 42, got => 42);

    # specified comparison operator
    $self->register_result(expected => 1, got => 2, cmp => '>=');
    $self->register_result(expected => 'second', got => 'first', cmp => 'lt');

    # using 'like' to match with a regex
    $self->register_result(expected => qr/.+bar.+/, got => 'foobarbaz', cmpself => 'like');

    # using 'oneOf' to select one of multiple values
    $self->register_result(expected => ['a', 'b', 'c' ], got => 'b', cmp => 'oneOf');

The default operator is 'eq'. The available comparison operators are:

    '==', '!=', '>', '>=', '<', '<=', '<=',
    'eq', 'ne', 'lt', 'le', 'gt', 'ge',
    'like' (regex comparison), 'oneOf' (list membership comparison)

You may also provide the following attributes to override validation results

=over

=item C<name>

By default, the validation result logs the C<name> attribute of the
Validation class. You may override the validation result name with this
attribute.

This value is not stored in the database. To disambiguate multiple results in the database, use
C<component>.

    $self->register_result(
        expected => 'hello',
        got      => 'hello',
        name     => 'hello_validation'
    );

=item C<message>

The default message stored in the validation result has the form, "Expected
$operator '$expected_value'. Got '$got_value'.". You may override this message
by specifying the C<message> attribute.

    $self->register_result(
        expected => 'hello',
        got      => 'hello',
        message  => 'Hello world!'
    );

=item C<category>

By default, the validation result stores the C<category> attribute of the
Validation class. You may override the validation result category with this
attribute.

    $self->register_result(
        expected => 'hello',
        got      => 'hello',
        category => 'BIOS'
    );

=item C<component>

You may specify the optional string attribute C<component> to set an
identifier to help identify a specific component under test.

    $self->register_result(
        expected     => 'OK',
        got          => $disk->{health},
        component    => $disk->{serial_number}
    );

=item C<hint>

You may specify the optional string attribute C<hint> to be stored B<if>
the validation fails. This string should help identify to a user how to fix the
validation failure. If the validation succeeds, the hint string is not stored
in the validation result.

    $self->register_result(
        expected  => 'hello',
        got       => 'bye',
        hint      => "Try saying 'hello' instead"
    );

=back

=cut

sub register_result ($self, %attrs) {
    my $expected = $attrs{expected};
    my $got      = $attrs{got};
    my $cmp_op   = $attrs{cmp} || 'eq';

    $self->die("'expected' value must be defined", level => 2)
        unless defined($expected);

    return $self->fail("'got' value is undefined") unless defined($got);

    $self->die("'got' value must be a scalar", level => 2) if ref($got);

    if ($cmp_op eq 'oneOf') {
        $self->die("'expected' value must be an array when comparing with 'oneOf'",
            level => 2)
            unless ref($expected) eq 'ARRAY';
    }
    elsif ($cmp_op eq 'like') {
        $self->die(
            "'expected' value must be a scalar or Regexp when comparing with 'like'",
            level => 2
        ) unless ref($expected) eq 'Regexp' || ref($expected) eq '';
    }
    else {
        $self->die(
            "'expected' value must be a scalar when comparing with '$cmp_op'",
            level => 2)
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
            scalar(grep $_[0] eq $_, $_[1]->@*);
        }
    };

    my $success = $cmp_dispatch->{$cmp_op}->($got, $expected);
    my $message;
    if ($cmp_op eq 'oneOf') {
        $message =
              'Expected one of: '
            .join(', ', map "'$_'", $expected->@*)
            .". Got '$got'.";
    }

    # For relational operators, we want to produce messages that do not change
    # between validation executions as long as the relation is constant.
    elsif (grep /$cmp_op/, ('>', '>=', '<', '<=', 'lt', 'le', 'gt', 'ge')) {
        $message = "Expected a value $cmp_op '$expected'.";
        $message .= $success ? ' Passed.' : ' Failed.';
    }
    else {
        $message = "Expected $cmp_op '$expected'. Got '$got'.";
    }

    my $validation_result = {
        message  => $attrs{message}  || $message,
        name     => $attrs{name}     || $self->name,
        category => $attrs{category} || $self->category,
        component    => $attrs{component},
        status       => $success ? _STATUS_PASS : _STATUS_FAIL,
        hint         => $success ? undef : $attrs{hint},
    };

    $self->log->debug(join('',
        "Validation ",
        $validation_result->{name} // "'unknown'",
        " had result ",
        $validation_result->{status},
        ": ",
        $validation_result->{message}
    ));

    $self->_push_validation_result($validation_result);
    return $self;
}

=head2 register_result_cmp_details

EXPERIMENTAL. A new way of registering validation results. Pass arguments as you would to
L<Test::Deep/cmp_deeply>, and a validation result is registered with the result and diagnostics
as appropriate.

=cut

sub register_result_cmp_details ($self, $got, $expected, $message) {
    require Test::Deep;
    my ($ok, $stack) = Test::Deep::cmp_details($got, $expected, $message);

    my $validation_result = {
        message  => $message,
        name     => $self->name,
        category => $self->category,
        status       => $ok ? _STATUS_PASS : _STATUS_FAIL,
        hint         => $ok ? undef : Test::Deep::deep_diag($stack),
    };

    $self->log->debug('Validation '.$self->name." had result $validation_result->{status}: $message");

    $self->_push_validation_result($validation_result);
    return $self;
}

=head2 die

Stop execution of the Validation immediately and record an error. The
attributes 'level' and 'hint' may be specified.

    $self->die('This validation cannot continue!') if $bad_condition;
    $self->die('This validation cannot continue!', hint => 'Here's how to fix it');
    $self->die('This exception happend 3 frames up', level => 3);

=cut

sub die ($self, $message, %args) {
    die Conch::ValidationError->new($message)->hint($args{hint})
        ->trace($args{level} || 1);
}

=head2 fail

Record a failing validation result with a message and continues execution. This
may be useful if you cannot validate some part of the input data but want to
continue validating other parts of the data.


    $self->fail('This validation fails but validation evaluation will continue')
        unless defined($data->{required_value});

The attributes C<name>, C<category>, C<component>, and C<hint> may be
specified like with L</register_result>.

    $self->fail('I fail!',
        name => 'some_component_validation',
        hint => 'How to fix this failure...'
    );

=cut

sub fail ($self, $message, %attrs) {
    my $validation_result = {
        message      => $message,
        name         => $attrs{name} || $self->name,
        category     => $attrs{category} || $self->category,
        component    => $attrs{component},
        status       => _STATUS_FAIL,
        hint         => $attrs{hint}
    };
    $self->_push_validation_result($validation_result);
    return $self;
}

1;
__END__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<https://www.mozilla.org/en-US/MPL/2.0/>.

=cut
