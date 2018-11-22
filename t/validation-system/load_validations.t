use Mojo::Base -strict;
use Test::More;
use Test::Deep;
use Conch::ValidationSystem;
use Test::Conch;
use Mojo::Log;
use Submodules;

open my $log_fh, '>', \my $fake_log or die "cannot open to scalarref: $!";
my $logger = Mojo::Log->new(handle => $log_fh);
sub reset_log { $fake_log = ''; seek $log_fh, 0, 0; }

my ($pg, $schema) = Test::Conch->init_db;
Conch::Pg->new($pg->uri);   # temporary

my $validation_rs = $schema->resultset('validation');

my @validation_modules = grep { $_->{Module} ne 'Conch::Validation' } Submodules->find('Conch::Validation');

subtest 'insert new validation rows' => sub {
    my $num_updates = Conch::ValidationSystem->load_validations($logger);
    note "inserted $num_updates validation rows";

    like($fake_log, qr/Loaded $_/, "logged something for $_")
        foreach @validation_modules;

    is($num_updates, scalar @validation_modules, 'all validation rows were inserted into the database');

    is(
        scalar @validation_modules,
        $validation_rs->active->count,
        'Number of validation modules matches number in the database',
    );
};

subtest 'try loading again' => sub {
    is(Conch::ValidationSystem->load_validations($logger), 0, 'No new validations loaded');
};

subtest 'update an existing validation' => sub {
    no warnings 'once', 'redefine';
    *Conch::Validation::DeviceProductName::description = sub { '  this is better than before!' };
    reset_log;

    is(Conch::ValidationSystem->load_validations($logger), 1, 'Updated validation loaded into the database');

    like($fake_log, qr/Loaded Conch::Validation::DeviceProductName/, 'logged the update');

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
    *Conch::Validation::DeviceProductName::version = sub { 2 };
    reset_log;

    is(Conch::ValidationSystem->load_validations($logger), 1, 'New version of validation loaded into the database');

    like($fake_log, qr/Loaded Conch::Validation::DeviceProductName/, 'logged the insert');

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
