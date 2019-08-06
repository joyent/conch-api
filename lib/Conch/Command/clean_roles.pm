package Conch::Command::clean_roles;

=pod

=head1 NAME

clean_roles - clean up unnecessary user_workspace_role entries

=head1 SYNOPSIS

    bin/conch clean_roles [-nv] [long options...]
        -n --dry-run  dry-run (no changes are made)
        -v --verbose  verbose

        --help        print usage message and exit

=cut

use Mojo::Base 'Mojolicious::Command', -signatures;
use Getopt::Long::Descriptive;

has description => 'Clean up unnecessary user_workspace_role entries';

has usage => sub { shift->extract_usage };  # extracts from SYNOPSIS

sub run ($self, @opts) {
    local @ARGV = @opts;
    my ($opt, $usage) = describe_options(
        # the descriptions aren't actually used anymore (mojo uses the synopsis instead)... but
        # the 'usage' text block can be accessed with $usage->text
        'clean_roles %o',
        [ 'dry-run|n',      'dry-run (no changes are made)' ],
        [ 'verbose|v',      'verbose' ],
        [],
        [ 'help',           'print usage message and exit', { shortcircuit => 1 } ],
    );

    my $uwr_rs = $self->app->db_user_workspace_roles
        ->prefetch([ qw(workspace user_account) ]);

    my $count = $uwr_rs->count;
    my $deleted = 0;

    while (my $uwr = $uwr_rs->next) {
        say 'considering workspace ', $uwr->workspace->name, ' for user ', $uwr->user_account->name,
            ' with role ', $uwr->role, '...';

        my $delete;

        if ($uwr->user_account->deactivated) {
            print '--> ', $uwr->role, ' role found for deactivated user. ';
            $delete = 1;
        }

        if (my $role_via = $self->app->db_workspaces
                ->workspaces_above($uwr->workspace_id)
                ->search_related('user_workspace_roles', {
                    'user_workspace_roles.user_id' => $uwr->user_id,
                    'user_workspace_roles.role' => { '>=' => \[ '?::user_workspace_role_enum', $uwr->role ] },
                })
                ->order_by({ -desc => 'role' })
                ->rows(1)
                ->as_subselect_rs
                ->prefetch('workspace')
                ->single) {

            print '--> ', $role_via->role, ' role found ',
                'in parent workspace ', $role_via->workspace->name, '. ';
            $delete = 1;
        }

        if ($delete) {
            ++$deleted;

            if ($opt->dry_run) {
                say 'Would delete record for ', $uwr->workspace->name, '.';
            }
            else {
                say 'Deleting record for ', $uwr->workspace->name, '.';
                $uwr->delete;
            }
        }
    }

    say $count, ' user_workspace_role records scanned; ', $deleted, ' ',
        ($opt->dry_run ? 'would be' : 'were'), ' deleted.';
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
