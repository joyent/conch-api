package Conch::DB::ResultSet::Workspace;
use v5.26;
use warnings;
use parent 'Conch::DB::ResultSet';

use experimental 'signatures';
use Conch::UUID 'is_uuid';
use Safe::Isa;
use List::Util 'none';

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

The resultset does *not* include the original workspace itself -- see
L</and_workspaces_beneath> for that.

=cut

sub workspaces_beneath ($self, $workspace_id) {
    Carp::croak('resultset should not have conditions') if $self->{cond};

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

    $self->search({ $self->current_source_alias.'.id' => { -in => \[ $query, $workspace_id ] } });
}

=head2 and_workspaces_beneath

As L<workspaces_beneath>, but also includes the original workspace.

C<$workspace_id> can be a single workspace_id, an arrayref of multiple distinct workspace_ids,
or a resultset, which must return a single column of distinct workspace_id(s)).

=cut

sub and_workspaces_beneath ($self, $workspace_id) {
    Carp::croak('resultset should not have conditions') if $self->{cond};

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

    $self->search({ $self->current_source_alias.'.id' => { -in => \[ $query, @binds ] } });
}

=head2 workspaces_above

Chainable resultset that finds all workspaces above the provided workspace id (that is, all
parent workspaces, up to the root).

The resultset does *not* include the original workspace itself -- see
L</and_workspaces_above> for that.

=cut

sub workspaces_above ($self, $workspace_id) {
    Carp::croak('resultset should not have conditions') if $self->{cond};

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

    $self->search({ $self->current_source_alias.'.id' => { -in => \[ $query, $workspace_id ] } });
}

=head2 and_workspaces_above

As L<workspaces_above>, but also includes the original workspace.

C<$workspace_id> can be a single workspace_id, an arrayref of multiple distinct workspace_ids,
or a resultset, which must return a single column of distinct workspace_id(s)).

=cut

sub and_workspaces_above ($self, $workspace_id) {
    Carp::croak('resultset should not have conditions') if $self->{cond};

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

    $self->search({ $self->current_source_alias.'.id' => { -in => \[ $query, @binds ] } });
}

=head2 add_role_column

Query for workspace(s) with an extra field attached to the result, containing information about
the effective role the user has for the workspace.

The indicated role is used directly, with no additional queries done (consequently "role_via"
will not appear in the serialized data).  This is intended to be used in preference to
L</with_role_via_data_for_user> when the user is a system admin.

=cut

sub add_role_column ($self, $role) {
    Carp::croak('role must be one of: ro, rw, admin')
        if !$ENV{MOJO_MODE} and none { $role eq $_ } qw(ro rw admin);

    $self->add_columns({
        role => [ \[ '?::user_workspace_role_enum as role', $role ] ],
    });
}

=head2 with_role_via_data_for_user

Query for workspace(s) with an extra field attached to the query which will signal the
workspace serializer to include the "role" and "role_via" columns, containing information about
the effective role the user has for the workspace.

Only one user_id can be calculated at a time. If you need to generate workspace-and-role data
for multiple users at once, you can manually do:

    $workspace->user_id_for_role($user_id);

before serializing the workspace object.

=cut

sub with_role_via_data_for_user ($self, $user_id) {
    # this just adds the user_id_for_role column to the result we get back. See
    # role_via_for_user for the actual role-via query.
    $self->add_columns({
        user_id_for_role => [ \[ '?::uuid as user_id_for_role', $user_id ] ],
    });
}

=head2 role_via_for_user

For a given workspace_id and user_id, find the user_workspace_role row that is responsible for
providing the user access to the workspace (the user_workspace_role with the greatest
role that is attached to an ancestor workspace).

=cut

sub role_via_for_user ($self, $workspace_id, $user_id) {
    Carp::croak('resultset should not have conditions') if $self->{cond};

    # because we check for duplicate role entries when creating user_workspace_role rows,
    # we "should" only have *one* row with the greatest role in the entire hierarchy...
    $self->and_workspaces_above($workspace_id)
        ->search_related('user_workspace_roles', { 'user_workspace_roles.user_id' => $user_id })
        ->order_by({ -desc => 'role' })
        ->rows(1)
        ->single;
}

=head2 admins

All the 'admin' users for the provided workspace(s).  Pass a true argument to also include all
system admin users in the result.

=cut

sub admins ($self, $include_sysadmins = undef) {
    my $rs = $self->search_related('user_workspace_roles', { role => 'admin' })
        ->related_resultset('user_account');

    $rs = $rs->union($self->result_source->schema->resultset('user_account')->search_rs({ is_admin => 1 }))
        if $include_sysadmins;

    return $rs
        ->active
        ->distinct
        ->order_by('user_account.name');
}

=head2 _workspaces_subquery

Generate values for inserting into a recursive query.
The first value is a string to be added after C<< WHERE <column> >>; the remainder are bind
values to be used in C<< \[ $query_string, @binds ] >>.

C<$workspace_id> can be a single workspace_id, an arrayref of multiple distinct workspace_ids,
or a resultset (which must return a single column of distinct workspace_id(s)).

=cut

sub _workspaces_subquery ($self, $workspace_id) {
    if (not ref $workspace_id and is_uuid($workspace_id)) {
        return ('= ?', $workspace_id);
    }

    if (ref $workspace_id eq 'ARRAY') {
        return ('IN(?)', $workspace_id);
    }

    if ($workspace_id->$_isa('DBIx::Class::ResultSetColumn')
            or $workspace_id->$_isa('DBIx::Class::ResultSet')) {
        $workspace_id = $workspace_id->as_query;
    }

    # $rs->as_query produces this: an sql query and list of bind parameters
    if (ref $workspace_id eq 'REF' and ref $workspace_id->$* eq 'ARRAY') {
        return (
            'IN '.$workspace_id->$*->[0],
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
one at L<http://mozilla.org/MPL/2.0/>.

=cut
# vim: set ts=4 sts=4 sw=4 et :
