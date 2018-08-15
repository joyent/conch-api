package Conch::DB::ResultSet::Workspace;
use v5.26;
use warnings;
use parent 'DBIx::Class::ResultSet';

=head1 NAME

Conch::DB::ResultSet::Workspace

=head1 DESCRIPTION

Interface to queries involving workspaces.

=head1 METHODS

=head2 workspaces_beneath

Chainable resultset that finds all sub-workspaces beneath the provided workspace id.

=cut

sub workspaces_beneath {
    my ($self, $workspace_id) = @_;

    my $query = q{
WITH RECURSIVE workspace_recursive (id, parent_workspace_id) AS (
  SELECT workspace.id, workspace.parent_workspace_id
    FROM workspace
    WHERE workspace.parent_workspace_id = ?
  UNION
    SELECT child.id, child.parent_workspace_id
    FROM workspace child, workspace_recursive parent
    WHERE child.parent_workspace_id = parent.id
)
SELECT workspace_recursive.id FROM workspace_recursive
};

    $self->search({ $self->current_source_alias . '.id' => { -in => \[ $query, $workspace_id ] } });
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
