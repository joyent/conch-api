# NAME

Test::Conch::Validation - Test Conch Validations

## METHODS

## test\_validation

A function to test a Conch Validation using a collection of provided test cases.

This function performs the following tests:

- Test whether the validation builds.
- Tests whether the validations defines the required `name`, `version`,
and `description` attributes.

The required arguments are the Conch Validation module as a string, keyword
arguments specifying optional models available to the Validation, and a keyword
argument specifying the cases for the test to use.

The available models are `hardware_product`, `device_location`,
`device_settings`, and `device`. Their attributes are defined with a hashref,
which will be constructed to the correct classes in the body of
["test\_validation"](#test_validation). For example:

```perl
    test_validation(
            'Conch::Validation::TestValidation',
            hardware_product => {
                    name => 'Product Name',
                    vendor => 'Product Vendor',
                    hardware_product_profile => {
                            num_cpu => 2
                    }
            },
            device_location => {
                    rack_unit       => 2,
                    rack => {
                            rack_layouts => [
                                    { rack_unit_start => 1 },
                                    { rack_unit_start => 2 },
                                    { rack_unit_start => 3 },
                            ],
                    },
            },
            device_settings => {
                    foo => 'bar'
            },
            device => {
                    triton_setup => 1,
            },

            cases => [ ... ]
    );
```

`cases` is a list of hashrefs defining each of the test cases. Each case
specifies the input data and attributes representing the expected results. Each
test case may raise an error (die) or may produce 0 or more validation results.
A test case is specified with a hashref with the attributes:

- `data`

    A hashref of the input data provide to the Validation. An empty hashref will be provided by default.

- `success_num`

    The number of expected successful validation results from running the
    Validation with the provided `data`. Defaults to 0.

- `failure_num`

    The number of expected failing validation results from running the Validation
    with the provided `data`. Defaults to 0

- `error_num`

    The number of expected 'error' validation results from running the Validation
    with the provided `data`. Defaults to 0.

- `description`

    Optional description of the test case. Provides documentation and adds the
    description to test failure messages.

- `debug`

    Optional boolean flag to provide additional diagnostic information when running
    the case using ["diag" in Test::More](https://metacpan.org/pod/Test::More#diag). This is helpful during development of test
    cases, but should be removed before committing.

Example:

```perl
    test_validation(
            'Conch::Validation::TestValidation',
            cases => [
                    {
                            data        => { hello => 'world' },
                            success_num => 3,
                            failure_num => 3,
                            description => 'Hello world test case',
                            debug       => 1
                    }
            ]
    );
```

# LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.
