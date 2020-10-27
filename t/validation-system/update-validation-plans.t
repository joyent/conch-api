use Mojo::Base -strict;
use Test::More;
use Test::Warnings;
use Test::Deep;
use Conch::LegacyValidationSystem;
use Test::Conch;
use Path::Tiny;
use Test::Fatal;

my $t = Test::Conch->new;
my $schema = $t->app->schema;

my $validation_system = Conch::LegacyValidationSystem->new(log => $t->app->log, schema => $schema);
my $validation_rs = $schema->resultset('legacy_validation');

# ether still likes to play a round or two if the course is nice
my @validation_modules = map { s{^lib/}{}; s{/}{::}g; s/\.pm$//r }
    grep -f && /\.pm$/, map keys $_->%*,
    path('lib/Conch/Validation')->visit(sub { $_[1]->{$_[0]} = 1 }, { recurse => 1 });

$validation_system->load_validations;
my $validation_plan = $schema->resultset('legacy_validation_plan')->create({
    name => 'my_humble_plan',
    description => 'sample plan containing a few validations that will be changed',
    legacy_validation_plan_members => [
        { legacy_validation => { name => 'product_name', version => 2 } },
        { legacy_validation => { name => 'firmware_current', version => 1 } },
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
    *Conch::Validation::DeviceProductName::version = sub () { 3 };
    $t->reset_log;

    # make sure we have the current state of the plan and members
    $validation_plan->discard_changes({ prefetch => { legacy_validation_plan_members => 'legacy_validation' } });
    $validation_system->update_validation_plans;

    is($validation_plan->deactivated, undef, 'original validation_plan is still active');

    my $new_validation_plan = $schema->resultset('legacy_validation_plan')->find(
        { name => 'my_humble_plan' },
        { prefetch => { legacy_validation_plan_members => 'legacy_validation' } },
    );

    is($new_validation_plan->id, $validation_plan->id, 'the "new" plan is still the original plan');

    cmp_deeply(
        [ $validation_plan->legacy_validations ],
        [
            methods(
                module => 'Conch::Validation::DeviceProductName',
                version => 2,
                deactivated => undef,
            ),
            methods(
                module => 'Conch::Validation::FirmwareCurrent',
                version => 1,
                deactivated => undef,
            ),
        ],
        'the original plan had version 1 of this validation',
    );

    cmp_deeply(
        [ $new_validation_plan->legacy_validations ],
        [
            methods(
                module => 'Conch::Validation::FirmwareCurrent',
                version => 1,
                deactivated => undef,
            ),
            methods(
                module => 'Conch::Validation::DeviceProductName',
                version => 3,
                deactivated => undef,
                description => 'this is better than before!',
            ),
        ],
        'the updated plan contains the new validation record with updated information',
    );

    $t->logs_are([
        'deactivated existing validation row for Conch::Validation::DeviceProductName',
        'created validation row for Conch::Validation::DeviceProductName',
        'validation plan my_humble_plan has a deactivated validation (product_name version 2): removing',
        'adding product_name version 3 to validation plan my_humble_plan',
    ]);
};

subtest 'a deactivated validation lives in the plan along with its newer version' => sub {
    my $new_validation_plan = $schema->resultset('legacy_validation_plan')->find(
        { name => 'my_humble_plan', deactivated => undef },
        { prefetch => { legacy_validation_plan_members => 'legacy_validation' } },
    );

    no warnings 'once', 'redefine';
    *Conch::Validation::DeviceProductName::description = sub () { 'even more improved' };
    *Conch::Validation::DeviceProductName::version = sub () { 4 };
    $t->reset_log;

    # deactivate old validation and create a new one for version 3
    $validation_system->load_validations;

    $t->logs_are([
        'deactivated existing validation row for Conch::Validation::DeviceProductName',
        'created validation row for Conch::Validation::DeviceProductName',
    ]);

    $new_validation_plan->add_to_legacy_validations({
        name => Conch::Validation::DeviceProductName->name,
        version => 4,
        description => Conch::Validation::DeviceProductName->description,
        module => 'Conch::Validation::DeviceProductName',
    });

    $validation_system->update_validation_plans;
    $new_validation_plan->discard_changes({ prefetch => { legacy_validation_plan_members => 'legacy_validation' } });

    is($new_validation_plan->deactivated, undef, 'the validation_plan is still active');

    cmp_deeply(
        [ $new_validation_plan->legacy_validations ],
        [
            methods(
                module => 'Conch::Validation::FirmwareCurrent',
                version => 1,
                deactivated => undef,
            ),
            methods(
                module => 'Conch::Validation::DeviceProductName',
                version => 4,
                deactivated => undef,
            ),
        ],
        'validation plan looks good',
    );

    $t->log_info_is('validation plan my_humble_plan has a deactivated validation (product_name version 3): removing');
};

subtest 'a validation module was deleted entirely' => sub {
    $t->reset_log;

    my $new_validation_plan = $schema->resultset('legacy_validation_plan')->find(
        { name => 'my_humble_plan', deactivated => undef },
        { prefetch => { legacy_validation_plan_members => 'legacy_validation' } },
    );

    my $old_validation = $validation_rs->create({
        name => 'old_and_crufty',
        version => 1,
        description => 'this validation used to be great but now it is not',
        module => 'Conch::Validation::OldAndCrufty',
    });
    $new_validation_plan->add_to_legacy_validations($old_validation);
    $validation_system->update_validation_plans;
    $new_validation_plan->discard_changes({ prefetch => { legacy_validation_plan_members => 'legacy_validation' } });
    $old_validation->discard_changes;

    is($new_validation_plan->deactivated, undef, 'the validation_plan is still active');

    cmp_deeply(
        $old_validation,
        methods(
            module => 'Conch::Validation::OldAndCrufty',
            version => 1,
            deactivated => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
        ),
        'the old validation that was in the plan has been deactivated',
    );

    is($new_validation_plan->legacy_validation_plan_members, 2,
        'the validation plan is back down to 2 active validations');

    cmp_deeply(
        [ $new_validation_plan->legacy_validations ],
        [
            methods(
                module => 'Conch::Validation::FirmwareCurrent',
                version => 1,
                deactivated => undef,
            ),
            methods(
                module => 'Conch::Validation::DeviceProductName',
                version => 4,
                deactivated => undef,
            ),
        ],
        'validation plan looks good',
    );

    $t->logs_are([
        'deactivating validation for no-longer-present modules: Conch::Validation::OldAndCrufty',
        'validation plan my_humble_plan has a deactivated validation (old_and_crufty version 1): removing',
    ]);
};

done_testing;
# vim: set ts=4 sts=4 sw=4 et :
