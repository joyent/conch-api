package Conch::DB::ResultSet::ValidationState;
use v5.26;
use warnings;
use parent 'Conch::DB::ResultSet';

use experimental 'signatures';

=head1 NAME

Conch::DB::ResultSet::ValidationState

=head1 DESCRIPTION

Interface to queries involving validation states.

=head1 METHODS

=head2 with_legacy_validation_results

Generates a resultset that adds the legacy_validation_results to the validation_state(s) in the
resultset (to be rendered as a flat list of results grouped by validation_state).

=cut

sub with_legacy_validation_results ($self) {
    $self
        ->prefetch({ legacy_validation_state_members => 'legacy_validation_result' })
        ->order_by('legacy_validation_state_members.result_order')
        ->search(undef, { join => { legacy_validation_state_members => { legacy_validation_result => 'legacy_validation' } } })
        ->add_columns({ (map +('legacy_validation_state_members.legacy_validation_result.'.$_ => 'legacy_validation.'.$_), qw(name version description)) });
}

=head2 with_validation_results

Generates a resultset that adds the validation_results to the validation_state(s) in the
resultset (to be rendered as a list json_schemas, each with a list of errors).

=cut

sub with_validation_results ($self) {
  $self
    ->search(undef,
      {
        join => { validation_state_members => { validation_result => 'json_schema' } },
        collapse => 1,
      },
    )
    # conflicts with collapse, and we sort in the serialization function anyway
    #->order_by('validation_state_members.result_order')
    ->add_columns({
      'validation_state_members.result_order' => 'validation_state_members.result_order',
      'validation_state_members.validation_result.description' => \q{json_schema.body->>'description'},
      'validation_state_members.validation_result.dollar_id' =>
        \q{concat_ws('/', '/json_schema', json_schema.type, json_schema.name, json_schema.version)},
      (map +('validation_state_members.validation_result.'.$_ => 'validation_result.'.$_),
        qw(id json_schema_id status data_location schema_location absolute_schema_location error)),
    });
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
