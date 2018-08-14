package Conch::DB::ResultSet::WorkspaceRecursive;
use v5.26;
use warnings;
use parent 'DBIx::Class::ResultSet';

=head1 NAME

Conch::DB::ResultSet::WorkspaceRecursive

=head1 DESCRIPTION

Interface to recursive queries against the 'workspace' table.

=head1 METHODS

=head2 workspaces_beneath

Given a parent workspace id, returns a (chainable) resultset for all
workspaces, recursively, that descend from that workspace.

=cut

sub workspaces_beneath {
	my ($self, $parent_workspace_id) = @_;

	$self->search(
		undef,
		{
			bind => [ $parent_workspace_id ],
		},
	);
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
