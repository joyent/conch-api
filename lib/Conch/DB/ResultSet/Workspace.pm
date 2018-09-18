package Conch::DB::ResultSet::Workspace;
use v5.26;
use warnings;
use parent 'Conch::DB::ResultSet';

use Conch::UUID 'is_uuid';

=head1 NAME

Conch::DB::ResultSet::Workspace

=head1 DESCRIPTION

Interface to queries involving workspaces.

Note: in the methods below, "above" and "beneath" are referring to the workspace tree,
where the root ("GLOBAL") workspace is considered to be at the top and child
workspaces hang below as nodes and leaves.

A parent workspace is "above" a given workspace; its children are "beneath".

=head1 METHODS

=head2 workspaces_beneath

Chainable resultset that finds all sub-workspaces beneath the provided workspace id.

=cut

sub workspaces_beneath {
    my ($self, $workspace_id) = @_;

    Carp::croak('missing workspace_id') if not defined $workspace_id;
    Carp::croak('resultset should not have conditions') if $self->{attrs}{cond};

    my $query = q{
WITH RECURSIVE workspace_children (id) AS (
  SELECT id
    FROM workspace base
    WHERE base.parent_workspace_id = ?
  UNION
    SELECT child.id
    FROM workspace child, workspace_children parent
    WHERE child.parent_workspace_id = parent.id
)
SELECT workspace_children.id FROM workspace_children
};

    $self->search({ $self->current_source_alias . '.id' => { -in => \[ $query, $workspace_id ] } });
}

=head2 and_workspaces_beneath

As L<workspaces_beneath>, but also includes the original workspace.

C<$workspace_id> can be a single workspace_id, an arrayref of multiple ids, or a subquery (via
C<< $resultset->as_query >>, which must return a single column of workspace_id(s)).

=cut

sub and_workspaces_beneath {
    my ($self, $workspace_id) = @_;

    Carp::croak('missing workspace_id') if not defined $workspace_id;
    Carp::croak('resultset should not have conditions') if $self->{attrs}{cond};

    my ($workspace_id_clause, @binds) = $self->_workspaces_subquery($workspace_id);

    my $query = qq{
WITH RECURSIVE workspace_and_children (id) AS (
  SELECT id
    FROM workspace base
    WHERE (base.id $workspace_id_clause)
  UNION
    SELECT child.id
    FROM workspace child, workspace_and_children parent
    WHERE child.parent_workspace_id = parent.id
)
SELECT DISTINCT workspace_and_children.id FROM workspace_and_children
};

    $self->search({ $self->current_source_alias . '.id' => { -in => \[ $query, @binds ] } });
}

=head2 workspaces_above

Chainable resultset that finds all workspaces above the provided workspace id (that is, all
parent workspaces, up to the root).
The resultset does *not* include the original workspace itself -- see
L</and_workspaces_above> for that.

=cut

sub workspaces_above {
    my ($self, $workspace_id) = @_;

    Carp::croak('missing workspace_id') if not defined $workspace_id;
    Carp::croak('resultset should not have conditions') if $self->{attrs}{cond};

    my $query = qq{
WITH RECURSIVE workspace_parents (id, parent_workspace_id) AS (
  SELECT base.id, base.parent_workspace_id
    FROM workspace base
    JOIN workspace base_child ON base_child.parent_workspace_id = base.id
    WHERE base_child.id = ?
  UNION
    SELECT parent.id, parent.parent_workspace_id
    FROM workspace parent, workspace_parents child
    WHERE parent.id = child.parent_workspace_id
)
SELECT workspace_parents.id FROM workspace_parents
};

    $self->search({ $self->current_source_alias . '.id' => { -in => \[ $query, $workspace_id ] } });
}

=head2 and_workspaces_above

Chainable resultset that finds all workspaces above the provided workspace id (that is, all
parent workspaces, up to the root).

The resultset includes the original workspace itself.

C<$workspace_id> can be a single workspace_id, an arrayref of multiple ids, or a subquery (via
C<< $resultset->as_query >>, which must return a single column of workspace_id(s)).

=cut

sub and_workspaces_above {
    my ($self, $workspace_id) = @_;

    # move to subfunction if carp_not doesn't include @ISA
    Carp::croak('missing workspace_id') if not defined $workspace_id;
    Carp::croak('resultset should not have conditions') if $self->{attrs}{cond};

    my ($workspace_id_clause, @binds) = $self->_workspaces_subquery($workspace_id);

    my $query = qq{
WITH RECURSIVE workspace_and_parents (id, parent_workspace_id) AS (
  SELECT id, parent_workspace_id
    FROM workspace base
    WHERE (base.id $workspace_id_clause)
  UNION
    SELECT parent.id, parent.parent_workspace_id
    FROM workspace parent, workspace_and_parents child
    WHERE parent.id = child.parent_workspace_id
)
SELECT DISTINCT workspace_and_parents.id FROM workspace_and_parents
};

    $self->search({ $self->current_source_alias . '.id' => { -in => \[ $query, @binds ] } });
}

=head2 associated_racks

Chainable resultset (in the Conch::DB::ResultSet::DatacenterRack namespace) that finds all
racks that are in this workspace (either directly, or via a datacenter_room).

To go in the other direction, see L<Conch::DB::ResultSet::DatacenterRack/associated_workspaces>.

=cut

sub associated_racks {
    my $self = shift;

    my $workspace_rack_ids = $self->related_resultset('workspace_datacenter_racks')
        ->get_column('datacenter_rack_id');

    my $workspace_room_rack_ids = $self->related_resultset('workspace_datacenter_rooms')
        ->related_resultset('datacenter_room')
        ->related_resultset('datacenter_racks')->get_column('id');

    $self->result_source->schema->resultset('DatacenterRack')->search(
        {
            'datacenter_rack.id' => [
                { -in => $workspace_rack_ids->as_query },
                { -in => $workspace_room_rack_ids->as_query },
            ],
        },
        { alias => 'datacenter_rack' },
    );
}

=head2 _workspaces_subquery

Generate values for inserting into a recursive query.
The first value is a string to be added after C<< WHERE <column> >>; the remainder are bind
values to be used in C<< \[ $query_string, @binds ] >>.

C<$workspace_id> can be a single workspace_id, an arrayref of multiple ids, or a subquery (via
C<< $resultset->as_query >>, which must return a single column of workspace_id(s)).

=cut

sub _workspaces_subquery {
    my ($self, $workspace_id) = @_;

    if (not ref $workspace_id and is_uuid($workspace_id)) {
        return ('= ?', $workspace_id);
    }

    if (ref $workspace_id eq 'ARRAY') {
        return ('= ANY(?)', $workspace_id);
    }

    if (ref $workspace_id eq 'REF' and ref $workspace_id->$* eq 'ARRAY') {
        return (
            'IN ' . $workspace_id->$*->[0],
            $workspace_id->$*->@[1 .. $workspace_id->$*->$#*],
        );
    }

    require Data::Dumper;
    Carp::croak('I don\'t know what to do with workspace_id argument ',
        Data::Dumper->new([ $workspace_id ])->Indent(0)->Terse(1)->Dump);
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
