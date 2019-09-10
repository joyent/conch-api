package Conch::DB::ResultSet::Workspace;
use v5.26;
use warnings;
use parent 'Conch::DB::ResultSet';

use experimental 'signatures';
use Carp ();
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
  UNION ALL
    SELECT child.id
    FROM workspace child, workspace_children parent
    WHERE child.parent_workspace_id = parent.id
)
SELECT workspace_children.id FROM workspace_children
};

    $self->search({ $self->current_source_alias.'.id' => { -in => \[ $query, $workspace_id ] } });
}

=head2 and_workspaces_beneath

As L</workspaces_beneath>, but also includes the original workspace.

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
  UNION ALL
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
  UNION ALL
    SELECT parent.id, parent.parent_workspace_id
    FROM workspace parent, workspace_parents child
    WHERE parent.id = child.parent_workspace_id
)
SELECT workspace_parents.id FROM workspace_parents
};

    $self->search({ $self->current_source_alias.'.id' => { -in => \[ $query, $workspace_id ] } });
}

=head2 and_workspaces_above

As L</workspaces_above>, but also includes the original workspace.

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
  UNION ALL
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
        role => [ \[ '?::role_enum as role', $role ] ],
    });
}

=head2 with_role_via_data_for_user

Query for workspace(s) with an extra field attached to the query which will signal the
workspace serializer to include the "role", "role_via_workspace_id" and
"role_via_organization_id" columns, containing information about the effective role the user
has for the workspace.

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

For a given workspace_id and user_id, find the user_workspace_role or
organization_workspace_role row that is responsible for providing the user access to the
workspace (the row with the greatest role that is attached to an ancestor workspace).

How the role is calculated:

=over 4

=item * The role on the user_organization_role role is B<not> used.

=item * The number of workspaces between C<$workspace_id> and the workspace attached to the
user_workspace_role or organization_workspace_role row is B<not> used.

=item * When both a user_workspace_role and organization_workspace_role row are found with the same
role, the record directly associated with the workspace (if there is one) is preferred;
otherwise, the user_workspace_role row is preferred.

=back

=cut

sub role_via_for_user ($self, $workspace_id, $user_id) {
    Carp::croak('resultset should not have conditions') if $self->{cond};

    # because we check for duplicate role entries when creating user_workspace_role rows,
    # we "should" only have *one* row with the greatest role in the entire hierarchy...
    my $uwr = $self->and_workspaces_above($workspace_id)
        ->search_related('user_workspace_roles', { user_id => $user_id })
        ->order_by({ -desc => 'role' })
        ->rows(1)
        ->single;

    return $uwr if $uwr and $uwr->workspace_id eq $workspace_id and $uwr->role eq 'admin';

    # there could be more than one organization that grants the user this role, but it
    # shouldn't matter which one we single out in the result.
    my $owr = $self->and_workspaces_above($workspace_id)
        ->search_related('organization_workspace_roles',
            { user_id => $user_id }, { join => { organization => 'user_organization_roles' } })
        ->order_by({ -desc => 'organization_workspace_roles.role' })
        ->rows(1)
        ->single;

    my (undef, $role_via) = sort {
        (!defined $a ? -1 : !defined $b ? 1 : 0)
     || $a->role_cmp($b->role)
     || ($a->workspace_id eq $workspace_id ? 1 : 0)
     || ($b->workspace_id eq $workspace_id ? -1 : 0)
     || 1   # give up; go with $a ($uwr)
    } ($uwr, $owr);

    return $role_via;
}

=head2 role_via_for_organization

For a given workspace_id and organization_id, find the organization_workspace_role row that is
responsible for providing the organization access to the workspace (the
organization_workspace_role with the greatest role that is attached to an ancestor
workspace).

=cut

sub role_via_for_organization ($self, $workspace_id, $organization_id) {
    Carp::croak('resultset should not have conditions') if $self->{cond};

    # because we check for duplicate role entries when creating organization_workspace_role rows,
    # we "should" only have *one* row with the greatest role in the entire hierarchy...
    $self->and_workspaces_above($workspace_id)
        ->search_related('organization_workspace_roles', { organization_id => $organization_id })
        ->order_by({ -desc => 'role' })
        ->rows(1)
        ->single;
}

=head2 admins

All the 'admin' users for the provided workspace(s).  Pass a true argument to also include all
system admin users in the result.

=cut

sub admins ($self, $include_sysadmins = undef) {
    my $direct_users_rs = $self->search_related('user_workspace_roles',
            { 'user_workspace_roles.role' => 'admin' })
        ->related_resultset('user_account');

    my $organization_users_rs = $self->search_related('organization_workspace_roles',
            { 'organization_workspace_roles.role' => 'admin' })
        ->related_resultset('organization')
        ->related_resultset('user_organization_roles')
        ->related_resultset('user_account');

    my $rs = $direct_users_rs->union_all($organization_users_rs);

    $rs = $rs->union_all($self->result_source->schema->resultset('user_account')->search_rs({ is_admin => 1 }))
        if $include_sysadmins;

    return $rs
        ->active
        ->distinct
        ->order_by('user_account.name');
}

=head2 with_user_role

Constrains the resultset to those where the provided user_id has (at least) the specified role
in at last one workspace in the resultset.  (Does not search recursively; add
C<< ->and_workspaces_above($workspace_id) >> to your resultset first, if this is what you want.)

=cut

sub with_user_role ($self, $user_id, $role) {
    Carp::croak('role must be one of: ro, rw, admin')
        if !$ENV{MOJO_MODE} and none { $role eq $_ } qw(ro rw admin);

    my $via_user_rs = $self->search(
        {
            $role ne 'ro' ? ('user_workspace_roles.role' => { '>=' => \[ '?::role_enum', $role ] } ) : (),
            'user_workspace_roles.user_id' => $user_id,
        },
        { join => 'user_workspace_roles' },
    );

    my $via_org_rs = $self->search(
        {
            $role ne 'ro' ? ('organization_workspace_roles.role' => { '>=' => \[ '?::role_enum', $role ] }) : (),
            'user_organization_roles.user_id' => $user_id,
        },
        { join => { organization_workspace_roles => { organization => 'user_organization_roles' } } } );

    return $via_user_rs->union_all($via_org_rs)->distinct;
}

=head2 user_has_role

Checks that the provided user_id has (at least) the specified role in at least one workspace in
the resultset. (Does not search recursively; add C<< ->and_workspaces_above($workspace_id) >>
to your resultset first, if this is what you want.)

Both direct C<user_workspace_role> entries and joined
C<user_organization_role> -> C<organization_workspace_role> entries are checked.

Returns a boolean.

=cut

sub user_has_role ($self, $user_id, $role) {
    Carp::croak('role must be one of: ro, rw, admin')
        if !$ENV{MOJO_MODE} and none { $role eq $_ } qw(ro rw admin);

    my $via_user_rs = $self->search_related('user_workspace_roles', { user_id => $user_id })
        ->with_role($role)
        ->related_resultset('user_account');

    my $via_org_rs = $self->related_resultset('organization_workspace_roles')
        ->with_role($role)
        ->related_resultset('organization')
        ->search_related('user_organization_roles', { user_id => $user_id })
        ->related_resultset('user_account');

    return $via_user_rs->union_all($via_org_rs)->exists;
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
