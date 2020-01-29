package Conch::Command::workspaces;

=pod

=head1 NAME

workspaces - view the workspace hierarchy

=head1 SYNOPSIS

    bin/conch workspaces [long options...]

        --help  print usage message and exit

=cut

use Mojo::Base 'Mojolicious::Command', -signatures;
use Getopt::Long::Descriptive;

has description => 'View all workspaces in their heirarchical order';

has usage => sub { shift->extract_usage };  # extracts from SYNOPSIS

sub run ($self, @opts) {
    local @ARGV = @opts;
    my ($opt, $usage) = describe_options(
        # the descriptions aren't actually used anymore (mojo uses the synopsis instead)... but
        # the 'usage' text block can be accessed with $usage->text
        'workspaces %o',
        [],
        [ 'help',           'print usage message and exit', { shortcircuit => 1 } ],
    );

    # traverse the entire workspace tree, depth-first.
    my $global_ws = $self->app->db_workspaces->search({ parent_workspace_id => undef })->single;

    _print_workspace_and_children($global_ws);
}

sub _print_workspace_and_children ($ws, $depth = 0) {
    my $indent = ' ' x (2 * $depth);
    say $indent, $ws->name, (' ' x (30 - 2*$depth - length($ws->name))), '  ', $ws->id;

    my $children_rs = $ws->workspaces;
    while (my $child = $children_rs->next) {
        _print_workspace_and_children($child, $depth + 1);
    }
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
# vim: set ts=4 sts=4 sw=4 et :
