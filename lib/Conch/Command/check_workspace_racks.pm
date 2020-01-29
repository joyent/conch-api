package Conch::Command::check_workspace_racks;

=pod

=head1 NAME

check_workspace_racks - Utility to check all workspace_rack entries are correct and complete

=head1 SYNOPSIS

    bin/conch check_workspace_racks [long options...]
        -n --dry-run    dry-run (no changes are made)
        -v --verbose    verbose

        --help          print usage message and exit

=head1 DESCRIPTION

For all racks, checks that necessary C<workspace_rack> rows exist (for every parent to the
workspace referenced by existing C<workspace_rack> entries). Missing rows are populated,
if C<--dry-run> not provided. Errors are identified, if C<--verbose> is provided.

=head1 EXIT CODE

Returns the number of errors found.

=cut

use Mojo::Base 'Mojolicious::Command', -signatures;
use Getopt::Long::Descriptive;

has description => 'verify the integrity of all workspace_rack rows';

has usage => sub { shift->extract_usage };  # extracts from SYNOPSIS

has 'dry_run';
has 'verbose';
has 'schema';

sub run ($self, @opts) {
    local @ARGV = @opts;
    my ($opt, $usage) = describe_options(
        # the descriptions aren't actually used anymore (mojo uses the synopsis instead)... but
        # the 'usage' text block can be accessed with $usage->text
        'check_workspace_racks %o',
        [ 'dry-run|n',      'dry-run (no changes are made)' ],
        [ 'verbose|v',      'verbose' ],
        [],
        [ 'help',  'print usage message and exit', { shortcircuit => 1 } ],
    );

    $self->$_($opt->$_) foreach qw(dry_run verbose);
    $self->schema($self->dry_run ? $self->app->ro_schema : $self->app->schema);

    # enable autoflush
    my $prev = select(STDOUT); $|++; select($prev);

    # we accumulate missing rows to add at the end, so we don't screw up our db cursors
    my @missing_rows;

    # check all racks are in workspace_rack for GLOBAL
    {
        my $workspace = $self->schema->resultset('workspace')->find({ parent_workspace_id => undef });
        say "\n".'checking workspace '.$workspace->name.' ('.$workspace->id.')...' if $self->verbose;
        my $rack_rs = $self->schema->resultset('rack');
        while (my $rack = $rack_rs->next) {
            push @missing_rows, $self->_check_entry($workspace, $rack);
        }
    }

    # foreach workspace
    #   get list of all its parents
    #   foreach workspace_rack entry
    #     check the rack has a workspace_rack row for all the parent workspaces too

    my $workspace_rs = $self->schema->resultset('workspace')
        ->search({ parent_workspace_id => { '!=' => undef } });
    while (my $workspace = $workspace_rs->next) {
        say "\n".'checking workspace '.$workspace->name.' ('.$workspace->id.')...' if $self->verbose;

        my @parent_workspaces = $self->schema->resultset('workspace')
            ->workspaces_above($workspace->id)->all;

        my $workspace_rack_rs = $workspace->related_resultset('workspace_racks');
        while (my $workspace_rack = $workspace_rack_rs->next) {
            my $rack_rs = $workspace_rack->related_resultset('rack');
            while (my $rack = $rack_rs->next) {
                # a lot of these checks are redundant, but whatever, there aren't too many rows...
                push @missing_rows, map $self->_check_entry($_, $rack), @parent_workspaces;
            }
        }
    }

    # now add all missing rows
    $self->schema->resultset('workspace_rack')->populate(\@missing_rows)
        if not $self->dry_run and @missing_rows;

    say "\nDone: ".scalar(@missing_rows).' missing workspace_rack entries found.';
    exit scalar @missing_rows;
}

# returns missing workspace_id, rack_id tuple, if error found
sub _check_entry ($self, $workspace, $rack) {
    return if $self->schema->resultset('workspace_rack')
        ->search({ workspace_id => $workspace->id, rack_id => $rack->id })->exists;

    say 'Missing entry for workspace '.$workspace->name.' ('.$workspace->id.') '
        .'and rack '.$rack->name.' ('.$rack->id.')'
        .($self->dry_run ? '' : ': fixing') if $self->verbose;

    return { workspace_id => $workspace->id, rack_id => $rack->id };
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
