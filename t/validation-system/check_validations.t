use v5.26;
use strict;
use warnings;

use Test::More;
use Test::Warnings;
use Test::Deep;
use Conch::ValidationSystem;
use Test::Conch;

use lib 't/lib';

my $uuid_re = Conch::UUID::UUID_FORMAT;

my $t = Test::Conch->new;
my $rw_schema = $t->app->schema;
my $ro_schema = $t->app->ro_schema;
my $validation_system = Conch::ValidationSystem->new(log => $t->app->log, schema => $ro_schema);

subtest 'inactive validation in an active plan' => sub {
    my $validation_plan = $rw_schema->resultset('validation_plan')->create({
        name => 'plan with inactive validation',
        description => '',
        validation_plan_members => [
            {
                validation => {
                    name => 'inactive validation',
                    version => 1,
                    description => '',
                    module => 'Conch::Validation::Empty',
                    deactivated => '2018-01-01',
                },
            },
        ],
    });

    $t->reset_log;
    my @modules = $validation_system->check_validation_plan($validation_plan);
    is(scalar @modules, 0, 'no valid validations in this plan');

    $t->log_is(
        re(qr/validation id $uuid_re "inactive validation" version 1 is inactive but is referenced by an active plan \("plan with inactive validation"\)/),
        'logged for inactive validation',
    );
    $t->log_is(
        re(qr/Validation plan id $uuid_re "plan with inactive validation" is valid/),
        'logged validation plan non-failure',
    );
};

subtest 'non-existent module' => sub {
    my $validation_plan = $rw_schema->resultset('validation_plan')->create({
        name => 'plan with missing module',
        description => '',
        validation_plan_members => [
            {
                validation => {
                    name => 'missing module',
                    version => 1,
                    description => '',
                    module => 'Conch::Validation::DoesNotExist',
                },
            },
        ],
    });

    $t->reset_log;
    my @modules = $validation_system->check_validation_plan($validation_plan);
    is(scalar @modules, 0, 'no valid validations in this plan');

    $t->log_is(
        re(qr{\Qcould not load Conch::Validation::DoesNotExist, used in validation plan "plan with missing module": Can't locate Conch/Validation/DoesNotExist.pm in \E}),
        'logged for missing validation module',
    );
    $t->log_is(
        re(qr/Validation plan id $uuid_re "plan with missing module" is not valid/),
        'logged validation plan failure',
    );
};

subtest 'module with syntax error' => sub {
    my $validation_plan = $rw_schema->resultset('validation_plan')->create({
        name => 'plan with broken module',
        description => '',
        validation_plan_members => [
            {
                validation => {
                    name => 'broken validation',
                    version => 1,
                    description => '',
                    module => 'Conch::Validation::Broken',
                },
            },
        ],
    });

    $t->reset_log;
    my @modules = $validation_system->check_validation_plan($validation_plan);
    is(scalar @modules, 0, 'no valid validations in this plan');

    $t->log_is(
        re(qr/could not load Conch::Validation::Broken, used in validation plan "plan with broken module": Missing right curly or square bracket/),
        'logged for broken validation module',
    );
    $t->log_is(
        re(qr/Validation plan id $uuid_re "plan with broken module" is not valid/),
        'logged validation plan failure',
    );
};

subtest 'module does not inherit from Conch::Validation' => sub {
    my $validation_plan = $rw_schema->resultset('validation_plan')->create({
        name => 'plan with module with wrong parentage',
        description => '',
        validation_plan_members => [
            {
                validation => {
                    name => 'validation with wrong parentage',
                    version => 1,
                    description => '',
                    module => 'Conch::Validation::WrongParentage',
                },
            },
        ],
    });

    $t->reset_log;
    my @modules = $validation_system->check_validation_plan($validation_plan);
    is(scalar @modules, 0, 'no valid validations in this plan');

    $t->log_is(
        re(qr/Conch::Validation::WrongParentage must be a sub-class of Conch::Validation/),
        'logged for validation module with wrong parentage',
    );
    $t->log_is(
        re(qr/Validation plan id $uuid_re "plan with module with wrong parentage" is not valid/),
        'logged validation plan failure',
    );
};

foreach my $field (qw(version name description)) {
    subtest "module has different $field than in the db" => sub {
        my $validation_plan = $rw_schema->resultset('validation_plan')->create({
            name => "plan with module with wrong $field",
            description => '',
            validation_plan_members => [
                {
                    validation => {
                        name => "wrong $field",
                        version => 1,
                        description => "validation with wrong $field",
                        module => 'Conch::Validation::Wrong'.ucfirst($field),
                    },
                },
            ],
        });

        $t->reset_log;
        my @modules = $validation_system->check_validation_plan($validation_plan);
        is(scalar @modules, 0, 'no valid validations in this plan');

        $t->log_is(
            re(qr/"$field" field for validation id $uuid_re does not match value in Conch::Validation::Wrong${\ ucfirst($field) } \("[^"]+" vs "[^"]+"\)/),
            "logged for validation module with wrong $field",
        );
        $t->log_is(
            re(qr/Validation plan id $uuid_re "plan with module with wrong $field" is not valid/),
            'logged validation plan failure',
        );
    };
}

subtest 'missing category' => sub {
    my $validation_plan = $rw_schema->resultset('validation_plan')->create({
        name => 'plan with module with missing category',
        description => '',
        validation_plan_members => [
            {
                validation => {
                    name => 'missing category',
                    version => 1,
                    description => 'validation with missing category',
                    module => 'Conch::Validation::MissingCategory',
                },
            },
        ],
    });

    $t->reset_log;
    my @modules = $validation_system->check_validation_plan($validation_plan);
    is(scalar @modules, 0, 'no valid validations in this plan');

    $t->log_is(
        re(qr/Conch::Validation::MissingCategory does not set a category/),
        'logged for validation module with missing category',
    );
    $t->log_is(
        re(qr/Validation plan id $uuid_re "plan with module with missing category" is not valid/),
        'logged validation plan failure',
    );
};

# clear out bad plans and validations from the db...
$rw_schema->resultset('validation_plan_member')->delete;
$rw_schema->resultset('validation_plan')->delete;
$rw_schema->resultset('validation')->delete;

subtest 'a real validator' => sub {
    require Conch::Validation::DeviceProductName;
    my $validator = Conch::Validation::DeviceProductName->new(
        log => $t->app->log,
        device => $ro_schema->resultset('device')->new_result({}),
    );

    my $validation_plan = $rw_schema->resultset('validation_plan')->create({
        name => 'a plan with a real validation',
        description => '',
        validation_plan_members => [
            {
                validation => {
                    (map +($_ => $validator->$_), qw(name version description)),
                    module => 'Conch::Validation::DeviceProductName',
                },
            },
        ],
    });

    $t->reset_log;
    my @modules = $validation_system->check_validation_plan($validation_plan);
    is(scalar @modules, 1, 'one valid validations in this plan');

    $t->log_is(
        re(qr/Validation plan id $uuid_re "a plan with a real validation" is valid/),
        'logged validation plan success',
    );
};

subtest 'all plans, and all real validation modules' => sub {
    $t->reset_log;
    my $num_validations_added = Conch::ValidationSystem->new(log => $t->app->log, schema => $rw_schema)
        ->load_validations;

    ok(
        (!grep /fatal/, map $_->[1], $t->app->log->history->@*),
        'there were no fatal errors with the existing validations',
    );

    my $validation_plan = $rw_schema->resultset('validation_plan')->create({
        name => 'a plan with all real validations',
        description => '',
    });

    my @validations = $rw_schema->resultset('validation')->active->all;
    is(scalar @validations, $num_validations_added + 1,
        'found all the validations we just loaded, plus the one from the previous test');
    $validation_plan->add_to_validations($_) foreach @validations;

    $t->reset_log;
    my $module_count = $validation_system->check_validation_plans;
    is($module_count, $num_validations_added + 1, 'all validations are in these plans, and valid');

    $t->logs_are(
        [
            re(qr/Validation plan id $uuid_re "a plan with a real validation" is valid/),
            re(qr/Validation plan id $uuid_re "a plan with all real validations" is valid/),
        ],
        'logged validation plan success',
    );
};

done_testing;
# vim: set ts=4 sts=4 sw=4 et :
