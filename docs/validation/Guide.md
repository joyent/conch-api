Guide: Writing, Deploying, and Testing a Conch Validation
=========================================================

### Table of Contents

* [Setting up the Conch Repository](#setting-up-the-conch-repository)
* [Creating a new Validation](#creating-a-new-validation)
* [Writing validation logic](#writing-validation-logic)
* [Validating input](#validating-input)
* [Dispatching on Device Attributes](#dispatching-on-device-attributes)
* [Writing unit tests for Validations](#writing-unit-tests-for-validations)
* [Deploying the Validation](#deploying-the-validation)
* [Using Validations with the Conch Shell](#using-validations-with-the-conch-shell)
  + [Listing validations](#listing-validations)
  + [Testing a validation with a device](#testing-a-validation-with-a-device)
  + [Creating and managing validation plans](#creating-and-managing-validation-plans)
  + [Testing validation plans](#testing-validation-plans)
* [Tips for Writing Validations](#tips-for-writing-validations)


### Overview of steps

1. Create a sub-class of `Conch::Validation`, the Validation base class. Set
   the `name`, `version`, `description`, and `category` fields, and write a
   `validate` method. The `validate` method body should register one or many
   results or an error.
2. Create a test file in `t/validation`. Use the `Test::Conch::Validation` test
   harness to write a test cases for your new validation. Verify it works as
   expected, especially if there are edge cases in the logic.
3. Commit the validation and validation test on a branch. [Create a pull
   request in the Conch repository](https://github.com/joyent/conch/pulls).
   Request a review.
4. Once your pull request has been reviewed, merged into master, and deployed,
   the validation is available on the system and via the API.
5. Using the [Conch Shell CLI tool](https://github.com/joyent/conch-shell), you
   can do the following:
	1. List available validations. `conch validations`
	2. Test a validation against a device using supplied data. `conch
	   validation VALIDATION_ID test DEVICE_ID`
	3. Add a validation to a validation plan. `conch validation-plan
	   VALIDATION_PLAN add-validation VALIDATION_ID`

Documentation for the [Validation base class](https://github.com/joyent/conch/blob/master/docs/validation/BaseValidation.md)
and [Validation test harness](https://github.com/joyent/conch/blob/master/docs/validation/TestingValidations.md)
are useful references for writing and testing a new Conch Validation.

Setting up the Conch Repository
-------------------------------

All Conch Validations are code modules committed in the [Conch
repository](https://github.com/joyent/conch). To add new validations, you must
create a local clone of the repository and add new validations as files in the
repository.

Clone the repository locally and set its path to your working directory. All
file paths in this tutorial are relative to the root of the repository.

See README.md for more about running Conch.

Creating a new Validation
-------------------------

Let's start by creating a simple yet valid validation. Create and write the
following code to the file `lib/Conch/Validation/MyValidation.pm`:

```perl
package Conch::Validation::MyValidation;

use Mojo::Base 'Conch::Validation';

has 'name' => 'my_validation_name';
has 'version' => 1;
has 'category' => 'EXAMPLE';
has 'description' => q(A basic example of a validation.);

sub validate {}

1;
```

This validation doesn't do anything useful and will not record results when
executed. But it satisfies all of the basic requirements to be loaded as a new
Validation into Conch. You could run `make run` in the top level directory and
this validation will be loaded into the system.

Valid validations must be sub-classes of the `Conch::Validation` module, and
the package must be under the `Conch::Validation` namespace. Validations use
the [`Mojo::Base`](https://metacpan.org/pod/Mojo::Base) module for sub-classing
and to set fields with the `has` directive. The following fields are required
for every validation:

* `name`: a short string name of the validation. The `name` and `version`
  values together must be unique for all validations in the system.
* `version`: an integer denoting the version of the validation for a given
  name. This field allows for supporting multiple versions of similar
  validations for legacy support.
* `category`: a short string signifier denoting the device component category
  being validated. Example categories are `BIOS`, `NET`, `DISK`, `CPU`,
  `RAM`. Upper case is used by convention.
* `description`: a longer, human-friendly description about the validation. The
  description should describe what is being validated and how.

All validations must define the `validate` method. `validate` defines the logic
of the validation. In our example, it does nothing, but next we will define
validation logic and register results.

Writing validation logic
------------------------

The `validate` method defines the validation logic. When a validation is run in
the validation system, the `validate` method is called for each validation.

The `validate` method receives two arguments: a 'self' reference and a hash ref
of the data input to the validation. Like so:

```perl
sub validate {
	my ($self, $data) = @_;
	# assuming the input data has a 'product_name' field
	my $product_name = $data->{product_name};
}
```

The validation logic should register at least one validation result and can
register as many results as desired. Validation results can be registered with
the following methods with different effects:


* [`$self->die('string')`](https://github.com/joyent/conch/blob/master/docs/validation/BaseValidation.md#die):
  Stop execution of the validation and record a validation result with status
  'error'. This should be used when the validation cannot continue. For example,
  when expected values in the `$data` hash ref are not present, call
  `$self->die()` with a description of the expected value

* [`$self->fail('string')`](https://github.com/joyent/conch/blob/master/docs/validation/BaseValidation.md#fail):
  Record a validation result with status 'fail' and continue execution of the
  validation. This may be used if some precondition is not satisfied but the
  validation should still continue.

* [`$self->register_result( expected => $a, got => $b, cmp => 'eq')`](https://github.com/joyent/conch/blob/master/docs/validation/BaseValidation.md#register_result):
  this is the workhorse of validation logic. It takes an expected and 'got' value
  and compares them with the operator `cmp`. The list of available comparison
  operators can be [found in the documentation.](https://github.com/joyent/conch/blob/master/docs/validation/BaseValidation.md#register_result)




For our example, let's validate that the input data reports that the device has
at least 1.21 gigawatts of power. This would be reported in JSON format and
de-serialized to the Perl hash ref provided as the `$data` argument. The input
data should look like `{ "power": { "gigawatts" : <number> } }`. We must be
sure to check we have received the data in the format we expect so our
validation is verifying the expected values. Update your validation file to the
following:


```perl
package Conch::Validation::MyValidation;

use Mojo::Base 'Conch::Validation';

has 'name' => 'my_validation_name';
has 'version' => 1;
has 'category' => 'EXAMPLE';
has 'description' => q(A basic example of a validation.);

sub validate {
	my ($self, $data) = @_;
	my $power = $data->{power};
	
	$self->die("'power' key is required in the input data") unless defined($power);
	$self->die("'power' value must be a hash") unless ref($power) eq 'HASH';
	
	my $gigawatts = $power->{gigawatts};
	
	$self->die("'gigawatts' is required in the input data") unless defined($gigawatts);
	$self->die("'gigawatts' must be a number') unless ( $gigawatts =~ /\d+(\.\d+)?/ );
	
	$self->register_result(
		expected => 1.21,
		got      => $gigawatts,
		cmp      => '>=',
		hint     => 'We require at least 1.21 gigawatts of power for this device'
	);
}

1;
```

Validating input
----------------

As you might notice in the example, it can be quite tedious to validate every
field in the input data hash and call `$self->die` if it's not present.
Instead, you may optionally define a 'schema' field. If `schema` is defined
will validate the input data against the schema before calling `validate` if
the data is valid. Any schema errors will be registered as validation results
with 'error' status.

The schema is defined using [JSON-Schema](http://json-schema.org), written with
a Perl hash instead of a JSON string. You can find [an easy JSON-Schema
tutorial here](http://json-schema.org/example1.html). It covers everything you
should need to write a schema for a Conch Validation.

**NOTE:** As the input data is required to be a hash, the root-level `{ type =>
'object', properties => {...} }` is omitted when defining validation schemas.
All top-level keys in the `schema` hash are assumed to be properties of the
hash. All top-level keys are also marked as `required`.

We can re-write our example validation using a schema like so:


```perl
package Conch::Validation::MyValidation;

use Mojo::Base 'Conch::Validation';

has 'name' => 'my_validation_name';
has 'version' => 1;
has 'category' => 'EXAMPLE';
has 'description' => q(A basic example of a validation.);

# NOTICE the 'sub {}' wrapping the hash!
# Mojo::Base requires non-scalar fields be defined this way.
has 'schema' => sub {
	{
		power => {
			type       => 'object',
			required   => ['gigawatts'],
			properties => {
				gigawatts => { type => 'number' }
			}
		}
	}
};

sub validate {
	my ($self, $data) = @_;
	# we can safely assume this hash path is present because it was verified with the schema
	my $gigawatts = $data->{power}->{gigawatts};
	
	$self->register_result(
		expected => 1.21,
		got      => $gigawatts,
		cmp      => '>=',
		hint     => 'We require at least 1.21 gigawatts of power for this device'
	);
}

1;
```

If the input data does not satisfy the schema, a validation result with status
'error' will be recorded describing all schema errors and the `validate` method
will not be executed.

Dispatching on Device Attributes
--------------------------------

Your validation may need to evaluate differently based on attributes of the
device under validation, such as the device hardware product, device location,
and device settings. The `$self` reference provides methods for accessing
details for the device under validation.  (You can also reach any other objects
in the database by following the relationship methods provided on these.)

* `$self->device`: the `Conch::DB::Result::Device` object representing the device
  under validation
* `$self->device_settings`: a hash ref of the device settings currently stored
  for the device under validation
* `$self->device_location`: the `Conch::DB::Result::DeviceLocation` object
  representing the location of the device under validation
* `$self->hardware_product`: the `Conch::DB::Result::HardwareProduct`
  object representing the hardware product of the expected hardware
  product for the device
* `$self->hardware_product_vendor`: a shortcut to the string containing the hardware
  product vendor name of the expected hardware product for the device
* `$self->hardware_product_name`: a shortcut to the string containing the hardware
  product name of the expected hardware product for the device
* `$self->hardware_product_profile`: the `Conch::DB::Result::HardwareProductProfile`
  object representing the hardware product profile of the expected hardware
  product for the device

If these methods are used and the device *does not* have details (for example,
if a device does not have a location assigned), the method will call
`$self->die` with a description of the condition that caused it to fail. This
is good! You can program conditions expecting a device to have a location, and
it will fail automatically if the device isn't assigned yet. No need to write
your own conditional checking logic.

A common validation use-case is comparing values reported, such as the amount
of RAM, to the value expected by the hardware product profile. For our
validation, let's assume that we require 1.21 gigawatts per PSU (stay with me
here), where the number of PSUs is specified by the `psu_total` field of the
hardware product profile. To add further complexity, this is only applied for
devices with the product name 'DMC-12'. For all other produce names, we require
the normal 1.21 gigawatts. Let's update our validation with this more complicated
logic:

```perl
package Conch::Validation::MyValidation;

use Mojo::Base 'Conch::Validation';

has 'name' => 'my_validation_name';
has 'version' => 1;
has 'category' => 'EXAMPLE';
has 'description' => q(A basic example of a validation.);

# NOTICE the 'sub {}' wrapping the hash!
# Mojo::Base requires non-scalar fields be defined this way.
has 'schema' => sub {
	{
		power => {
			type     => 'object',
			required => ['gigawatts'],
			properties => {
				gigawatts => { type => 'number' }
			}
		}
	}
};

sub validate {
	my ($self, $data) = @_;
	# we can safely assume this hash path is present because it was verified with the schema
	my $gigawatts = $data->{power}->{gigawatts};
	
	my $expected_gigawatts;
	if ($self->hardware_product_name eq 'DMC-12') {
		$expected_gigawatts = 1.21 * $self->hardware_product_profile->psu_total;
	} else {
		$expected_gigawatts = 1.21;
	}
	$self->register_result(
		expected => $expected_gigawatts,
		got      => $gigawatts,
		cmp      => '>=',
		hint     => "We require at least $expected_gigawatts gigawatts for this device"
	);
}

1;
```

Writing unit tests for Validations
---------------------------------

Writing unit tests for your new validation is strongly encouraged. A test
harness is provided to make this process easy and practical. At minimum, you
specify your validation module name and an array of tests cases to execute with
your validation.

A test cases is simply a hash with fields describing the input and expected
results. Each test case must specify a `data` field for the input data, which
must be a hash ref. The test case should specify a `description` string field
to help with documenting the test case and debugging test failures. A test case
should then define one or many of the following:

* `dies`: If set to 1, we expect the validation to call `$self->die` based on
  the input. Defaults to 0.
* `success_num`: The number of results with status 'pass' to be registered
  based on the input. Defaults to 0.
* `failure_num`: The number of results with status 'fail' to be registered
  based on the input. Defaults to 0.

An example to test the validation we've written is provided below. To test this
yourself, write to the file `t/validation/my_validation_v1.t` and run `carton
exec prove t/validation/my_validation_v1.t`.

```perl
use Test::More;
use Test::Conch::Validation 'test_validation';

test_validation(
	'Conch::Validation::MyValidation',
	hardware_product => { name => 'Test Product' },
	cases => [
		{
			description => 'Providing no input data dies',
			data        => {},
			dies        => 1
		},
		{
			description => 'If 'power' is not a hash, it dies',
			data        => { power => 'bad power'},
			dies        => 1
		},
		{
			description => 'If 'gigawatts' is not a number, it dies',
			data        => { power => { gigawatts => 'bad' } },
			dies        => 1
		},
		{
			description => 'If 'gigawatts' is not at least 1.21, it fails',
			data        => { power => { gigawatts => 1.00 } },
			failure_num => 1
		},
		{
			description => 'If 'gigawatts' is exactly least 1.21, it passes',
			data        => { power => { gigawatts => 1.21 } },
			success_num => 1
		},
		{
			description => 'If 'gigawatts' is more than 1.21, it passes',
			data        => { power => { gigawatts => 1.22 } },
			success_num => 1
		},
	]
);

done_testing();
```

This tests the basic logic, but doesn't test the edge case we introduced with
1.21 gigawatts multiplied by the number of PSUs for devices with the hardware
product name 'DMC-12'. The validation harness also allows us to provide fake
objects, like hardware product and hardware profile, to be used in the
validation under test. This is done by defining named arguments in the
`test_validation` function like `hardware_product`. [The list of available
named arguments and an example are given in the documentation for the test
harness](https://github.com/joyent/conch/blob/master/docs/validation/TestingValidations.md).

In the same file, after the `test_validation()` call and before
`done_testing();`, we add tests for the edge case:

```perl
test_validation(
	'Conch::Validation::MyValidation',
	hardware_product => {
		name => 'DMC-12',
		# profile has 2 PSUs
		profile => { psu_total => 2 },
	},
	cases => [
		{
			description => 'If 'gigawatts' is 1.21, it fails',
			data        => { power => { gigawatts => 1.21 } },
			failure_num => 1
		},
		{
			description => 'If 'gigawatts' is exactly 2 * 1.21 = 2.42, it passes',
			data        => { power => { gigawatts => 2.42 } },
			success_num => 1
		},
		{
			description => 'If 'gigawatts' is more than 2.42, it passes',
			data        => { power => { gigawatts => 2.5 } },
			success_num => 1
		},
	]
);
```

Deploying the Validation
------------------------

A Conch Validation must be deployed in the production Conch instance to be
available. After you've written and tested your validation, commit it on a
branch and [create a pull request on the Conch Github
repository](https://github.com/joyent/conch/pulls). Request someone from the
Conch team to review and merge it.

The validation will be deployed in the next [versioned
release](https://github.com/joyent/conch/releases) after it has been merged
into master.

However, your validation won't actually be included in one of the active validation plans.
To get it included, create an issue on GitHub requesting that it be added to
the switch and/or server plan(s).


Using Validations with the Conch Shell
--------------------------------------

The [Conch Shell](https://github.com/joyent/conch-shell) CLI tool provides
commands for managing validations and validation plans. [You may download the
latest version of a compiled binary for your system
here.](https://github.com/joyent/conch-shell/releases). Save the binary
somewhere on your $PATH. To set up and authenticate your account, run the
command `conch profile create` once installed.

### Listing validations

`conch validations` lists all available validations.  Each validation has an
UUID ID. In commands on a single validation, you may use the full idea or the
first 8 hexadecimal digits of the UUID (all characters before the first dash).
For example, `39cb3ab6-1963-4c9a-94ea-e2d9258d8be0` may be shortened to
`39cb3ab6`.

### Testing a validation with a device

`conch validation VALIDATION_ID test DEVICE_ID` tests a validation against a
device. The `DEVICE_ID` is a device's serial number. The command returns a
table of the validation results from running the validation. *This does not
store the validations results in the database*. This command is intended for
testing a new validation or new reporting agent code.

`conch validation VALIDATION_ID test DEVICE_ID` receives the input
data to validate from STDIN. The input data must be in JSON format. For
example, you can do any of the following to test a validation:

```bash
conch validation 39cb3ab6 test COFFEE < report_data.json

# 'jo' is https://github.com/jpmens/jo
jo 'power[gigawatts]=1.21'  | conch validation 39cb3ab6 test COFFEE

conch validation 39cb3ab6 test COFFEE <<EOF
{
	"power" : {
		"gigawatts" : 1.21
	}
}
EOF
```

Optionally, you also start the command (hitting enter after the command) and
type in your input data and end with `^D` (Control-D)

```
conch validation 39cb3ab6 test COFFEE<ENTER>
{
	"power" : {
		"gigawatts" : 1.21
	}
}
^D
```

### Creating and managing validation plans

Validation plans are collections of validations. Validations plans are is
executed during device report ingest and by orchestration workflows.
Validations are independent and un-ordered within a validation plan. A given
validation may be in 0 or many validation plans, and a validation plan may have
0, 1, or many validations associated with it.

Only users who are system admins (i.e., [they have the `is_admin` flag set
on their user account](https://github.com/joyent/rfd/blob/master/rfd/0134/README.md) may
create and manage validation plans. However, anyone with a Conch account may
list and test validation plans.

`conch validation-plans get` lists all available validation plans. Like
validation IDs, you may shorten the UUID to the first 8 characters in commands.

`conch validation-plans create --name NAME_OF_NEW_VALIDATION_PLAN --description
DESCRIPTION_OF_PLAN` creates a new validation plan. A new validation plan will
have no validations associated with it.

`conch validation-plan PLAN_ID validations` lists all validations associated
with the plan.

`conch validation-plan PLAN_ID add-validation VALIDATION_ID` associates a
validation with the validation plan. You may use a short ID for the
`VALIDATION_ID` field.

`conch validation-plan PLAN_ID remove-validation VALIDATION_ID` removes an
associated validation from the validation plan. You may use a short ID for the
`VALIDATION_ID` field.

### Testing validation plans

`conch validation-plan VALIDATION_PLAN_ID test DEVICE_ID` tests a validation
plan against a device. Any authenticated user may test a validation plan
against a device. Testing with a validation plan works identically to testing
with a single validation, except the input data is processed by all validations
in the validation plan.  This command is useful for verifying a device report
can satisfy the schemas for all validations in a validation plans when
developing a reporting agent.

Like testing a validation, the command receives the JSON-formatted input data
from STDIN. Any of the following options work.

```bash
conch validation-plan 39cb3ab6 test COFFEE < report_data.json

# 'jo' is https://github.com/jpmens/jo
jo 'power[gigawatts]=1.21' | conch validation-plan 39cb3ab6 test COFFEE

conch validation-plan 39cb3ab6 test COFFEE <<EOF
{
	"power" : {
		"gigawatts" : 1.21
	}
}
EOF

conch validation 39cb3ab6 test COFFEE<ENTER>
{
	"power" : {
		"gigawatts" : 1.21
	}
}
^D
```

Tips for Writing Validations
----------------------------

Below are some tips for writing effective validations.

### Provide user-friendly hints

`$self->die`, `$self->fail`, and `$self->register_result` can be called with an
`hint` attribute to provide a user-friendly message to help diagnose and fix
the issue. For example:

```perl
$self->register_result(
	expected => $expected_temp,
	got      => $temp,
	cmp      => '<',
	hint     => "This device is too hot! Make it cooler!"
);
```

### Die fast and loud

If there's some condition you don't expect, use `$self->die`. Don't try to
write complicated logic to handle all possible conditions. This leads into the
next tip.

### Write _small_ validations

Don't try to write a validation for all possible hardware products. Validations
can be mixed-and-matched in validation plans, and those plans associated with
different hardware products.  For example, instead of writing conditional logic
to handle the case for the "DMC-12" product, we could have written two separate
validations: one for products where we expect 1.21 * $number_of_PSUs gigawatts
and one where 1.21 gigawatts is always expected.

The advantage is we don't have to change the validation if there's a new
hardware product where same edge case should apply. We only need to associate
the validation with a validation plan the hardware product should use.
