package Conch::DB::ResultSet;
use v5.26;
use warnings;
use parent 'DBIx::Class::ResultSet';

=head1 NAME

Conch::DB::ResultSet

=head1 DESCRIPTION

Base class for our resultsets, to allow us to add on additional functionality from what is
available in core L<DBIx::Class>.

=cut

__PACKAGE__->load_components(
    '+Conch::DB::Deactivatable',                # provides active, deactivate
    'Helper::ResultSet::RemoveColumns',         # provides remove_columns (must be applied early!)
    'Helper::ResultSet::OneRow',                # provides one_row
    'Helper::ResultSet::Shortcut::HRI',         # provides hri: raw unblessed + uninflated data
    'Helper::ResultSet::Shortcut::Prefetch',    # provides prefetch
    'Helper::ResultSet::Shortcut::OrderBy',     # provides order_by
    'Helper::ResultSet::Shortcut::Rows',        # provides rows
    'Helper::ResultSet::Shortcut::Distinct',    # provides distinct
    '+Conch::DB::ResultsExist',                 # provides exists
    'Helper::ResultSet::Shortcut::Columns',     # provides columns
    'Helper::ResultSet::Shortcut::Page',        # provides page
    'Helper::ResultSet::CorrelateRelationship', # provides correlate
    'Helper::ResultSet::Shortcut::AddColumns',  # provides add_columns
    '+Conch::DB::AsEpoch',                      # provides as_epoch
    'Helper::ResultSet::Shortcut::GroupBy',     # provides group_by
);

1;
__END__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<http://mozilla.org/MPL/2.0/>.

=cut
# vim: set ts=4 sts=4 sw=4 et :
