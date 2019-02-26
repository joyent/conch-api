package Conch::DB::Util;

use v5.26;
use warnings;
use experimental 'signatures';

use Path::Tiny;
use List::Util qw(maxstr uniqnum);
use Mojo::Log;
use Conch::ValidationSystem;
use App::Sqitch;
use App::Sqitch::Config;
use App::Sqitch::Command;
use Try::Tiny;

=pod

=head1 NAME

Conch::DB:::Util - utility functions for working with the Conch database

=head1 METHODS

=head2 get_credentials

Return the credentials and connection options suitable for passing to L<Conch::DB> for both
read-write and read-only connections, containing keys:

returns a hashref containing keys:

    dsn
    username
    password
    options
    ro_username
    ro_password

Overrides are accepted from the following environment variables:

    POSTGRES_DB
    POSTGRES_HOST
    POSTGRES_USER
    POSTGRES_PASSWORD

If not all credentials can be determined from environment variables, the C<$config> is read
from. It should be a database configuration hashref (such as that extracted from F<conch.conf>
at the appropriate hash key), or a subref that returns the hashref.

=cut

sub get_credentials ($config, $log = Mojo::Log->new) {

    # look for overrides from the environment first

    my $dsn;
    if ($ENV{POSTGRES_DB} or $ENV{POSTGRES_HOST}) {
        # dsn is as defined in https://metacpan.org/pod/DBI#connect
        # and https://metacpan.org/pod/DBD::Pg#connect:
        # dbi:DriverName:dbname=database_name[;host=hostname[;port=port]]
        my $db = $ENV{POSTGRES_DB} // 'conch';
        my $host = $ENV{POSTGRES_HOST} // 'localhost';
        $dsn = 'dbi:Pg:dbname='.$db.';host='.$host;
    }

    my $username = $ENV{POSTGRES_USER};
    my $password = $ENV{POSTGRES_PASSWORD};
    my $options = {
        AutoCommit          => 1,
        AutoInactiveDestroy => 1,
        PrintError          => 0,
        PrintWarn           => 0,
        RaiseError          => 1,
    };

    my ($ro_username, $ro_password);

    # fall back to config hash if needed (password is permitted to be undef)

    if (not $dsn or not $username) {
        $config = $config->() if ref $config eq 'CODE';

        if (not $config->{dsn}) {
            my $message = 'Your conch.conf is out of date. Please update it following the format in conch.conf.dist';
            $log->fatal($message);
            die $message;
        }

        $dsn //= $config->{dsn};
        $username //= $config->{username};
        $password //= $config->{password};

        ($ro_username, $ro_password) = $config->@{qw(ro_username ro_password)};

        $options = {
            $options->%*,
            ($config->{options} // {})->%*,
        };
    }

    if (not defined $ro_username) {
        $log->info('read-only database credentials not provided; falling back to main credentials');
        ($ro_username, $ro_password) = ($username, $password);
    }

    return +{
        dsn => $dsn,
        username => $username,
        password => $password,
        options => $options,
        ro_username => $ro_username,
        ro_password => $ro_password,
    };
}

=head2 get_postgres_version

Retrieves the current running version of postgres.

=cut

sub get_postgres_version ($schema) {
    my $pgsql_version = $schema->storage->dbh_do(sub ($storage, $dbh) {
        my ($v) = $dbh->selectrow_array('select version()');
        return $v;
    });
}

=head2 initialize_db

Initialize an empty database with the conch user and role and create empty tables.

=cut

sub initialize_db ($schema) {
    my $debug = $schema->storage->debug;
    my $do = $debug
        ? sub { my $dbh = shift; say STDERR @_; $dbh->do(@_) }
        : sub { shift->do(@_) };

    $schema->storage->dbh_do(sub ($storage, $dbh, @args) {
        $dbh->$do('CREATE ROLE conch LOGIN');
        $dbh->$do('CREATE DATABASE conch OWNER conch');
        say STDERR 'loading sql/schema.sql' if $debug;
        $dbh->do(path('sql/schema.sql')->slurp_utf8) or die 'SQL load failed in sql/schema.sql';
        $dbh->$do('RESET search_path');  # go back to "$user", public
    });

    _run_sqitch_command($schema, 'deploy', ['--log-only']);
}

sub _uri_from_schema ($schema) {
	my ( $dsn, $user, $password, $conf ) = $schema->storage->connect_info->@*;
    # DBI:Pg:dbname=test;host=127.0.0.1;port=15432;user=postgres
	$dsn =~ /dbi:(?<engine>[^:]+):dbname=(?<dbname>[^;]+)
                                         (?:;host=(?<host>[^;]+))?
                                         (?:;port=(?<port>[^;]+))?
                                         (?:;user=(?<user>[^;]+))?
            /xi;
	return "db:$+{engine}://$+{user}\@$+{host}:$+{port}/$+{dbname}";
}

sub _run_sqitch_command ( $schema, $cmd, $args = [], $log = Mojo::Log->new ) {
	$ENV{SQITCH_TARGET} = _uri_from_schema($schema);
	my $config    = App::Sqitch::Config->new();
	my $sqitch    = App::Sqitch->new( { config => $config } );
	my $cmd_class = App::Sqitch::Command->class_for( $sqitch, $cmd );
	my $command = $cmd_class->create(
		{
			sqitch => $sqitch,
			config => $config,
			args   => $args,
		}
	);
	try {
		$command->execute(@$args);
	}
	catch {
		$log->error($_);
	};
}

=head2 get_migration_level

Returns as a tuple the id of the latest database migration that has been applied, and the
latest migration found in the sqitch plan

=cut

sub get_migration_level ($schema) {
	$ENV{SQITCH_TARGET} = _uri_from_schema($schema);
	my $config    = App::Sqitch::Config->new();
	my $sqitch    = App::Sqitch->new( { config => $config } );
    my $target = App::Sqitch::Target->new(sqitch => $sqitch);
	return (
		$target->engine->latest_change_id,
		$target->plan->last->id,
	);
}

=head2 migrate_db

Bring the Conch database up to the latest migration.

=cut

sub migrate_db ($schema, $log = Mojo::Log->new) {
    _run_sqitch_command($schema, 'deploy', [], $log);
}

=head2 create_validation_plans

Sets up the static validation plans currently in use by Conch.

=cut

sub create_validation_plans ($schema, $log = Mojo::Log->new) {
    # create validation records from modules on disk
    Conch::ValidationSystem->new(
        schema => $schema,
        log => $log,
    )->load_validations;

    # create plans with stock validations
    $schema->resultset('validation_plan')->create($_) foreach (
        {
            name => 'Conch v1 Legacy Plan: Server',
            description => 'Validation plan containing all validations run in Conch v1 on servers',
            validation_plan_members => [
                map +{ validation => { module => $_, deactivated => undef } },
                    qw(
                        Conch::Validation::CpuCount
                        Conch::Validation::CpuTemperature
                        Conch::Validation::DimmCount
                        Conch::Validation::DiskSmartStatus
                        Conch::Validation::DiskTemperature
                        Conch::Validation::FirmwareCurrent
                        Conch::Validation::LinksUp
                        Conch::Validation::NicsNum
                        Conch::Validation::DeviceProductName
                        Conch::Validation::RamTotal
                        Conch::Validation::SasHddNum
                        Conch::Validation::SasSsdNum
                        Conch::Validation::SlogSlot
                        Conch::Validation::SwitchPeers
                        Conch::Validation::UsbHddNum
                    )
            ],
        },
        {
            name => 'Conch v1 Legacy Plan: Switch',
            description => 'Validation plan containing all validations run in Conch v1 on switches',
            validation_plan_members => [
                map +{ validation => { module => $_, deactivated => undef } },
                    qw(
                        Conch::Validation::BiosFirmwareVersion
                        Conch::Validation::CpuTemperature
                        Conch::Validation::DeviceProductName
                    )
            ],
        },
    );
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
# vim: set ts=4 sts=4 sw=4 et :
