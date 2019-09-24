use Mojo::Base -strict;
use Test::More;
use Test::Warnings;
use Test::Deep;
use Conch::ValidationSystem;
use Test::Conch;
use Path::Tiny;
use Test::Fatal;

my $t = Test::Conch->new;
my $schema = $t->app->schema;

my $validation_system = Conch::ValidationSystem->new(log => $t->app->log, schema => $schema);
my $validation_rs = $schema->resultset('validation');

# ether still likes to play a round or two if the course is nice
my @validation_modules = map { s{^lib/}{}; s{/}{::}g; s/\.pm$//r }
    grep -f && /\.pm$/, map keys $_->%*,
    path('lib/Conch/Validation')->visit(sub { $_[1]->{$_[0]} = 1 }, { recurse => 1 });

$validation_system->load_validations;
my $validation_plan = $schema->resultset('validation_plan')->create({
    name => 'my_humble_plan',
    description => 'sample plan containing a few validations that will be changed',
    validation_plan_members => [
        { validation => { name => 'product_name', version => 1 } },
        { validation => { name => 'firmware_current', version => 1 } },
    ],
});

subtest 'an existing validation has changed but the version was not incremented' => sub {
    no warnings 'once', 'redefine';
    *Conch::Validation::DeviceProductName::description = sub () { 'I made a change but forgot to update the version' };
    $t->reset_log;

    like(
        exception { $validation_system->update_validation_plans },
        qr/\Qcannot create new row for validation named product_name, as there is already a row with its name and version (did you forget to increment the version in Conch::Validation::DeviceProductName?)\E/,
        'attempt to update validation plans exploded',
    );
};

subtest 'increment a validation\'s version (presumably the code changed too)' => sub {
    no warnings 'once', 'redefine';
    *Conch::Validation::DeviceProductName::description = sub () { 'this is better than before!' };
    *Conch::Validation::DeviceProductName::version = sub () { 2 };
    $t->reset_log;

    $validation_system->update_validation_plans;
    $validation_plan->discard_changes({ prefetch => { validation_plan_members => 'validation' } });

    like(
        $validation_plan->deactivated,
        qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/,
        'original validation_plan was deactivated',
    );

    cmp_deeply(
        [ $validation_plan->validation_plan_members ],
        superbagof(
            methods(validation => methods(
                module => 'Conch::Validation::DeviceProductName',
                version => 1,
                description => 'Validate reported product name matches product name expected in rack layout',
                deactivated => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
            )),
        ),
        'the validation in the original plan that was modified has been deactivated',
    );

    my $new_validation_plan = $schema->resultset('validation_plan')->find(
        { name => 'my_humble_plan', deactivated => undef },
        { prefetch => { validation_plan_members => 'validation' } },
    );

    cmp_deeply(
        [ $new_validation_plan->validation_plan_members ],
        superbagof(
            methods(validation => methods(
                module => 'Conch::Validation::DeviceProductName',
                version => 2,
                deactivated => undef,
                description => 'this is better than before!',
            )),
        ),
        'the new validation_plan contains the new validation record with updated information',
    );

    $t->log_is(
        'plan my_humble_plan had 2 active validations and now has 1: deactivating the plan and replacing it with a new one containing updated validations',
        'logged the plan update',
    );
};

subtest 'a validation module was deleted entirely' => sub {
    my $new_validation_plan = $schema->resultset('validation_plan')->find(
        { name => 'my_humble_plan', deactivated => undef },
        { prefetch => { validation_plan_members => 'validation' } },
    );

    $new_validation_plan->add_to_validations(
        $validation_rs->create({
            name => 'old_and_crufty',
            version => 1,
            description => 'this validation used to be great but now it is not',
            module => 'Conch::Validation::OldAndCrufty',
        })
    );

    $validation_system->update_validation_plans;

    $new_validation_plan->discard_changes({ prefetch => { validation_plan_members => 'validation' } });

    cmp_deeply(
        $new_validation_plan,
        all(
            methods(deactivated => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/)),
            listmethods(validation_plan_members => [ (ignore) x 3 ]),
        ),
        'second version of validation_plan (with 3 validations) was deactivated; the old validation i the plan has been deactivated',
    );

    cmp_deeply(
        [ $new_validation_plan->validation_plan_members ],
        superbagof(
            methods(validation => methods(
                module => 'Conch::Validation::OldAndCrufty',
                version => 1,
                deactivated => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
            )),
        ),
        'the old validation in the plan has been deactivated',
    );

    is($schema->resultset('validation_plan')->search({ name => 'my_humble_plan' })->all, 3,
        'the validation plan has now gone through three iterations');

    my $newest_validation_plan = $schema->resultset('validation_plan')->find(
        { name => 'my_humble_plan', deactivated => undef },
        { prefetch => { validation_plan_members => 'validation' } },
    );

    is($newest_validation_plan->validation_plan_members, 2,
        'newest version of the validation plan is back down to 2 active validations');

    $t->logs_are(
        [
            'deactivating validation for no-longer-present modules: Conch::Validation::OldAndCrufty',
            'plan my_humble_plan had 3 active validations and now has 2: deactivating the plan and replacing it with a new one containing updated validations',
        ],
        'logged the validation deactivation and plan update',
    );
};

done_testing;
# vim: set ts=4 sts=4 sw=4 et :
