#!/usr/bin/env perl
use strict;
use warnings;
use autodie qw{ open close };
use v5.20;

use DBI;
use Data::Printer;
use DateTime::Format::Pg;
use IO::File;
use Getopt::Long;
use Pod::Usage;


my $output_dir = "validation_results";
my $start_date;
my $end_date;

my $database = 'conch';
my $user = 'conch';
my $password = '';

my $help;

GetOptions(
  "out_dir=s"  => \$output_dir,
  "start_date=s" => \$start_date,
  "end_date=s"   => \$end_date,
  "user|u=s" => \$user,
  "database|d=s" => \$database,
  "password|p=s" => \$password,
  "help|h" => \$help
) or pod2usage(-verbose => 99);

pod2usage(-verbose => 99) if $help;


my $pg_time_parser = DateTime::Format::Pg->new();

my $dbh = DBI->connect("dbi:Pg:dbname=$database", $user, $password);

$dbh or die "cannot connect to Postgres. Make sure env variables PGDATABASE, PGUSER, and any other required are set";

my $sth;

my $date_clause = '';
if ($start_date || $end_date) {
  $date_clause = "WHERE ";
  $date_clause .= "created >= date '$start_date' " if $start_date;
  $date_clause .= "AND " if $start_date && $end_date;
  $date_clause .= "created <= date '$end_date'" if $end_date;
}

$sth = $dbh->prepare(qq{
  select created from device_validate order by created desc limit 10;
  SELECT distinct date_trunc('day', created AT TIME ZONE 'UTC')::date as day
  FROM device_validate
  $date_clause
  ORDER by day ASC;
});
$sth->execute();
my $days = $sth->fetchall_arrayref;
$sth->finish;

$sth = $dbh->prepare(q{
  SELECT json_build_object(
    'device_id', device_id,
    'created', created AT TIME ZONE 'UTC',
    'validation_result', validation
  ) from device_validate
  WHERE created AT TIME ZONE 'UTC' > ($1::date)
    AND created AT TIME ZONE 'UTC' < ($1::date + interval '1 day') 
  order by created ASC
},  { pg_server_prepare => 1 });


mkdir $output_dir;

for my $row (@{$days}) {
  my $day = $row->[0];
  say "Processing $day...";
  $sth->bind_param(1, $day);
  $sth->execute();
  my $results = $sth->fetchall_arrayref;
  open(my $fh, ">" , "$output_dir/$day.json.log");
  print $fh  join("\n", map { $_->[0] } @{$results});
  close $fh;
  say "Done";
}

$dbh->disconnect;


__END__

=head1 NAME

device-validation-result-dump - Dump device validation results from Conch DB

=head1 SYNOPSIS

device-validation-result-dump [options]

  Options:

   --out_dir                   directory dumped files will be written. Will be created
   --start_date=<YYYY-MM-DD>   date to start the dump, inclusive
   --end_date=<YYYY-MM-DD>     date to end the dump, inclusive
   --database, d=<DB name>     Conch database name
   --user, u=<DB username>     database username
   --password, p=<DB password> database password
   --help, h                   this help message

B<device-validation-result-dump> will dump all of the validations results into
files split by day (UTC) the valition result was recorded. The validation
results 1 per in line in ascending timestamp order (earliest first) and
formated as JSON with the following schema:

  {
    "device_id": <device id>,
    "created": <timestamp>,
    "validation_result": <validation object>
  }

=cut
