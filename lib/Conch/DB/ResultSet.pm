package Conch::DB::ResultSet;
use v5.26;
use warnings;
use parent 'DBIx::Class::ResultSet';

=head1 NAME

Conch::DB::ResultSet

=head1 DESCRIPTION

Base class for our resultsets, to allow us to add on additional functionality from what is
available in core L<DBIx::Class>.

=head1 METHODS

=for stopwords hri prefetch

Methods added are:

=over 4

=item * L<active|Conch::DB::Helper::ResultSet::Deactivatable/active>

=item * L<add_columns|DBIx::Class::Helper::ResultSet::Shortcut/add_columns>

=item * L<as_epoch|Conch::DB::Helper::ResultSet::AsEpoch/as_epoch>

=item * L<columns|DBIx::Class::Helper::ResultSet::Shortcut/columns>

=item * L<correlate|DBIx::Class::Helper::ResultSet::CorrelateRelationship/correlate>

=item * L<deactivate|Conch::DB::Helper::ResultSet::Deactivatable/deactivate>

=item * L<distinct|DBIx::Class::Helper::ResultSet::Shortcut/distinct>

=item * L<except|DBIx::Class::Helper::ResultSet::SetOperations/except>

=item * L<except_all|DBIx::Class::Helper::ResultSet::SetOperations/except_all>

=item * L<exists|Conch::DB::Helper::ResultSet::ResultsExist/exists>

=item * L<group_by|DBIx::Class::Helper::ResultSet::Shortcut/group_by>

=item * L<hri|DBIx::Class::Helper::ResultSet::Shortcut/hri>

=item * L<intersect|DBIx::Class::Helper::ResultSet::SetOperations/intersect>

=item * L<intersect_all|DBIx::Class::Helper::ResultSet::SetOperations/intersect_all>

=item * L<one_row|DBIx::Class::Helper::ResultSet::OneRow/one_row>

=item * L<order_by|DBIx::Class::Helper::ResultSet::Shortcut/order_by>

=item * L<page|DBIx::Class::Helper::ResultSet::Shortcut/page>

=item * L<prefetch|DBIx::Class::Helper::ResultSet::Shortcut/prefetch>

=item * L<remove_columns|DBIx::Class::Helper::ResultSet::RemoveColumns/remove_columns>

=item * L<rows|DBIx::Class::Helper::ResultSet::Shortcut/rows>

=item * L<union|DBIx::Class::Helper::ResultSet::SetOperations/union>

=item * L<union_all|DBIx::Class::Helper::ResultSet::SetOperations/union_all>

=item * L<with_role|Conch::DB::Helper::ResultSet::WithRole/with_role>

=back

=cut

__PACKAGE__->load_components(
    '+Conch::DB::Helper::ResultSet::Deactivatable', # provides active, deactivate
    'Helper::ResultSet::RemoveColumns',         # provides remove_columns (must be applied early!)
    'Helper::ResultSet::OneRow',                # provides one_row
    'Helper::ResultSet::Shortcut::HRI',         # provides hri: raw unblessed + uninflated data
    'Helper::ResultSet::Shortcut::Prefetch',    # provides prefetch
    'Helper::ResultSet::Shortcut::OrderBy',     # provides order_by
    'Helper::ResultSet::Shortcut::Rows',        # provides rows
    'Helper::ResultSet::Shortcut::Distinct',    # provides distinct
    '+Conch::DB::Helper::ResultSet::ResultsExist',  # provides exists
    'Helper::ResultSet::Shortcut::Columns',     # provides columns
    'Helper::ResultSet::Shortcut::Page',        # provides page
    'Helper::ResultSet::CorrelateRelationship', # provides correlate
    'Helper::ResultSet::Shortcut::AddColumns',  # provides add_columns
    '+Conch::DB::Helper::ResultSet::AsEpoch',   # provides as_epoch
    'Helper::ResultSet::SetOperations',         # provides union, intersect, except, and *_all
    'Helper::ResultSet::Shortcut::GroupBy',     # provides group_by
    '+Conch::DB::Helper::ResultSet::WithRole',  # provides with_role
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
