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

=head2 latest_completed_state_per_plan

Generates a resultset that returns the single most recent *completed* validation_state entry
per validation plan (using whatever other search criteria are already in the resultset).

The query will be closed off as a subselect (that additional chaining will SELECT FROM),
so it makes a difference whether you add things to the resultset before or after calling this
method.

=cut

sub latest_completed_state_per_plan ($self) {
    my $me = $self->current_source_alias;
    $self->search(
        { "$me.completed" => { '!=' => undef } },
        {
            order_by => { -desc => "$me.completed" },
            '+select' => [{
                '' => \'row_number() over (partition by validation_plan_id order by completed desc)',
                -as => 'result_num',
            }],
        },
    )
    ->as_subselect_rs
    ->search({ result_num => 1 });
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
