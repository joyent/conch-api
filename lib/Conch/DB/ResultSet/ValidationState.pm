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

=head2 with_results

Generates a resultset that adds the validation_results to the validation_state(s) in the
resultset.

=cut

sub with_results ($self) {
    $self
        ->prefetch({ legacy_validation_state_members => 'legacy_validation_result' })
        ->order_by('legacy_validation_state_members.result_order')
        ->search(undef, { join => { legacy_validation_state_members => { legacy_validation_result => 'validation' } } })
        ->add_columns({ (map +('legacy_validation_state_members.legacy_validation_result.'.$_ => 'validation.'.$_), qw(name version description)) });
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
