package Conch::Command::create_test_validation_results;

=pod

=head1 NAME

create_test_validation_results - create new-style validation_result entries for testing

=head1 SYNOPSIS

  bin/conch create_test_validation_results [-de] [long options...]

    -n --dry-run            dry-run (no changes are made)
    --help                  print usage message and exit

    -d STR --device STR     the device serial number to use for the results
    -e STR --email STR      the creation user's email address
    --[no-]rvs --[no-]reuse-validation-state
                            use an existing validation_state (otherwise, create a new one)

=cut

use Mojo::Base 'Mojolicious::Command', -signatures;
use Getopt::Long::Descriptive;
use Mojo::JSON 'to_json';

has description => 'create test validation results';

has usage => sub { shift->extract_usage };  # extracts from SYNOPSIS

has 'dry_run';

sub run ($self, @opts) {
  local @ARGV = @opts;

  my ($opt, $usage) = describe_options(
    # the descriptions aren't actually used anymore (mojo uses the synopsis instead)... but
    # the 'usage' text block can be accessed with $opt->usage
    'create_test_validation_results %o',
    [ 'device|d=s',     'the device serial number to use for the results', { required => 1 } ],
    [ 'email|e=s',      'the creation user\'s email address', { required => 1 } ],
    [ 'reuse-validation-state|rvs!',    'use an existing validation_state (otherwise, create a new one)', { default => 0 } ],
    [],
    [ 'help',           'print usage message and exit', { shortcircuit => 1 } ],
  );

  my $user_id = $self->app->db_user_accounts->search({ email => $opt->email })->get_column('id')->single;
  my @json_schemas;

  # create /json_schema/test/test/1 and /json_schema/test/test/2
  foreach my $version (1..2) {
    push @json_schemas, $self->app->db_json_schemas->find_or_create({
      type => 'test',
      name => 'test',
      version => $version,
      body => to_json({
        description => 'a test schema',
        properties => {
          foo => JSON::PP::false,
          bar => { type => 'integer', minimum => $version },
        },
      }),
      created_user_id => $user_id,
    });
  }

  my $device = $self->app->db_devices->find({ serial_number => $opt->device });

  my $validation_state =
    $opt->reuse_validation_state
      ? $self->app->db_validation_states
        ->search({ device_id => $device->id })
        ->order_by({ -desc => 'created' })
        ->rows(1)
        ->single
      : $self->app->db_validation_states
        ->create({
          status => 'fail',
          device_id => $device->id,
          hardware_product_id => $device->hardware_product_id,
          device_report_id => $device->related_resultset('device_reports')
            ->order_by({ -desc => 'created' })
            ->rows(1)
            ->get_column('id')
            ->single,
        });

  die 'most recent validation_state (id '.$validation_state->id.' does not have status=fail'
    if $validation_state->status ne 'fail';


  my $result_order = 0;
  $self->app->db_validation_state_members->create({
    result_order => $result_order++,
    validation_state_id => $validation_state->id,
    validation_result => $_,
  })
  foreach (
    +{
      json_schema_id => $json_schemas[0]->id,
      status => 'pass',
    },
    {
      json_schema_id => $json_schemas[1]->id,
      status => 'fail',
      data_location => '/foo',
      schema_location => '/properties/foo',
      absolute_schema_location => '/json_schema/test/test/1#/properties/foo',
      error => 'property not permitted',
    },
    {
      json_schema_id => $json_schemas[1]->id,
      status => 'fail',
      data_location => '/bar',
      schema_location => '/properties/bar',
      absolute_schema_location => '/json_schema/test/test/1#/properties/bar',
      error => 'value is smaller than 2',
    },
  );

  say 'validation_results created for device serial '.$opt->device;
}

1;
__END__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<https://www.mozilla.org/en-US/MPL/2.0/>.

=cut
# vim: set sts=2 sw=2 et :
