use Mojo::Base -strict;
use Test::More;
use Test::Deep;
use Conch::ValidationSystem;
use Test::Conch;
use Mojo::Log;
use Path::Tiny;

open my $log_fh, '>', \my $fake_log or die "cannot open to scalarref: $!";
my $logger = Mojo::Log->new(handle => $log_fh);
sub reset_log { $fake_log = ''; seek $log_fh, 0, 0; }

my ($pg, $schema) = Test::Conch->init_db;

my $validation_system = Conch::ValidationSystem->new(log => $logger, schema => $schema);
my $validation_rs = $schema->resultset('validation');

# ether still likes to play a round or two if the course is nice
my @validation_modules = map { s{^lib/}{}; s{/}{::}g; s/\.pm$//r }
    grep -f && /\.pm$/, map keys $_->%*,
    path('lib/Conch/Validation')->visit(sub { $_[1]->{$_[0]} = 1 }, { recurse => 1 });

subtest 'insert new validation rows' => sub {
    my $num_updates = $validation_system->load_validations;
    note "inserted $num_updates validation rows";

    like($fake_log, qr/Created entry for $_/, "logged something for $_")
        foreach @validation_modules;

    is($num_updates, scalar @validation_modules, 'all validation rows were inserted into the database');

    is(
        scalar @validation_modules,
        $validation_rs->active->count,
        'Number of validation modules matches number in the database',
    );
};

subtest 'try loading again' => sub {
    is($validation_system->load_validations, 0, 'No new validations loaded');
};

subtest 'update an existing validation' => sub {
    no warnings 'once', 'redefine';
    *Conch::Validation::DeviceProductName::description = sub () { '  this is better than before!' };
    reset_log;

    is($validation_system->load_validations, 1, 'Updated validation loaded into the database');

    like($fake_log, qr/Updated entry for Conch::Validation::DeviceProductName/, 'logged the update');

    cmp_deeply(
        $validation_rs->search({ module => 'Conch::Validation::DeviceProductName' })->single,
        methods(
            module => 'Conch::Validation::DeviceProductName',
            version => 1,
            description => 'this is better than before!',
        ),
        'entry was updated',
    );
};

subtest 'deactivate a validation and update its version (presumably the code changed too)' => sub {
    $validation_rs->search({ module => 'Conch::Validation::DeviceProductName' })->deactivate;
    no warnings 'once', 'redefine';
    *Conch::Validation::DeviceProductName::version = sub () { 2 };
    reset_log;

    is($validation_system->load_validations, 1, 'New version of validation loaded into the database');

    like($fake_log, qr/Created entry for Conch::Validation::DeviceProductName/, 'logged the insert');

    cmp_deeply(
        $validation_rs->search({
                module => 'Conch::Validation::DeviceProductName',
                deactivated => { '!=' => undef },
            })->single,
        methods(
            module => 'Conch::Validation::DeviceProductName',
            version => 1,
            description => 'this is better than before!',
            deactivated => bool(1),
        ),
        'old entry was deactivated',
    );

    cmp_deeply(
        $validation_rs->active->search({ module => 'Conch::Validation::DeviceProductName' })->single,
        methods(
            module => 'Conch::Validation::DeviceProductName',
            version => 2,
            description => 'this is better than before!',
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

done_testing;
# vim: set ts=4 sts=4 sw=4 et :
