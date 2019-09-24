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
$t->app->log->max_history_size(50);

my $validation_system = Conch::ValidationSystem->new(log => $t->app->log, schema => $schema);
my $validation_rs = $schema->resultset('validation');

# ether still likes to play a round or two if the course is nice
my @validation_modules = map { s{^lib/}{}; s{/}{::}g; s/\.pm$//r }
    grep -f && /\.pm$/, map keys $_->%*,
    path('lib/Conch/Validation')->visit(sub { $_[1]->{$_[0]} = 1 }, { recurse => 1 });

subtest 'insert new validation rows' => sub {
    my ($num_deactivated, $num_created) = $validation_system->load_validations;
    note "deactivated $num_deactivated validation rows";
    note "inserted $num_created validation rows";

    $t->logs_are(
        [ map re(qr/^created validation row for $_/), @validation_modules ],
        'logged something for all validation modules',
        'info',
    );

    is($num_deactivated, 0, 'there were no validations to deactivate');
    is($num_created, scalar @validation_modules, 'all validation rows were inserted into the database');

    is(
        scalar @validation_modules,
        $validation_rs->active->count,
        'Number of validation modules matches number in the database',
    );
};

subtest 'try loading again' => sub {
    is($validation_system->load_validations, 0, 'No validations needed to change');
};

subtest 'an existing validation has changed but the version was not incremented' => sub {
    no warnings 'once', 'redefine';
    *Conch::Validation::DeviceProductName::description = sub :prototype() { 'I made a change but forgot to update the version' };
    $t->reset_log;

    like(
        exception { $validation_system->load_validations },
        qr/\Qcannot create new row for validation named product_name, as there is already a row with its name and version (did you forget to increment the version in Conch::Validation::DeviceProductName?)\E/,
        'attempt to update validations exploded',
    );
};


subtest 'increment a validation\'s version (presumably the code changed too)' => sub {
    no warnings 'once', 'redefine';
    *Conch::Validation::DeviceProductName::description = sub :prototype() { 'this is better than before!' };
    *Conch::Validation::DeviceProductName::version = sub :prototype() { 2 };
    $t->reset_log;

    my ($num_deactivated, $num_created) = $validation_system->load_validations;
    is($num_deactivated, 1, 'the old version was deactivated');
    is($num_created, 1, 'the new version was inserted');

    $t->logs_are(
        [
            re(qr/deactivated existing validation row for Conch::Validation::DeviceProductName/),
            re(qr/created validation row for Conch::Validation::DeviceProductName/),
        ],
        'logged the deactivation and insert',
    );

    cmp_deeply(
        $validation_rs->search({
                module => 'Conch::Validation::DeviceProductName',
                deactivated => { '!=' => undef },
            })->single,
        methods(
            module => 'Conch::Validation::DeviceProductName',
            version => 1,
            description => 'Validate reported product name matches product name expected in rack layout',
            deactivated => re(qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/),
        ),
        'old entry was deactivated',
    );

    cmp_deeply(
        $validation_rs->active->search({ module => 'Conch::Validation::DeviceProductName' })->single,
        methods(
            module => 'Conch::Validation::DeviceProductName',
            version => 2,
            description => 'this is better than before!',
            deactivated => undef,
        ),
        'new entry was added for bumped version',
    );

    is(
        $validation_rs->active->count,
        scalar @validation_modules,
        'Number of active validation modules remains the same as before',
    );

    is(
        $schema->resultset('validation')->count,
        scalar @validation_modules + 1,
        'Number of total validation modules has gone up by one',
    );
};

subtest 'a validation module was deleted entirely' => sub {
    my $old_validation = $validation_rs->create({
        name => 'old_and_crufty',
        version => 1,
        description => 'this validation used to be great but now it is not',
        module => 'Conch::Validation::OldAndCrufty',
    });

    my ($num_deactivated, $num_created) = $validation_system->load_validations;
    is($num_deactivated, 1, 'the old validation was deactivated');
    is($num_created, 0, 'there are no new validations to insert');

    $old_validation->discard_changes;
    like($old_validation->deactivated, qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3,9}Z$/,
        'the validation has been deactivated');

    $t->log_is(
        re(qr/deactivating validation for no-longer-present modules: Conch::Validation::OldAndCrufty/),
        'logged the deactivation',
    );
};

done_testing;
# vim: set ts=4 sts=4 sw=4 et :
