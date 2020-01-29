package Conch::Command::new_organizations;

=pod

=head1 NAME

new_organizations - Create new organization data (one-off for v3 launch)

=head1 SYNOPSIS

    bin/conch new_organizations [long options...]

        --help        print usage message and exit

=cut

use Mojo::Base 'Mojolicious::Command', -signatures;
use Getopt::Long::Descriptive;
use List::Util 'minstr';

has description => 'create new organization data';

has usage => sub { shift->extract_usage };  # extracts from SYNOPSIS

sub run ($self, @opts) {
    my $admin_id = $self->app->db_user_accounts->search({ email => 'ether@joyent.com' })->get_column('id')->single;

    my $joyent_org = $self->app->db_organizations->find_or_create({
        name => 'Joyent',
        description => 'Joyent employees',
        user_organization_roles => [
            { user_id => $admin_id, role => 'admin' },
            map +{ user_id => $_, role => 'ro' },
                $self->app->db_user_accounts->search({ email => { -like => '%@joyent.com' }, id => { '!=' => $admin_id } })
                    ->get_column('id')->all
        ],
    });
    my $samsung_org = $self->app->db_organizations->find_or_create({
        name => 'Samsung',
        description => 'Samsung employees',
        user_organization_roles => [
            { user_id => $admin_id, role => 'admin' },
            map +{ user_id => $_, role => 'ro' },
                $self->app->db_user_accounts->search({ email => { -like => '%@samsung.com' }, id => { '!=' => $admin_id } })
                    ->get_column('id')->all
        ],
    });
    my $dcops_org = $self->app->db_organizations->find_or_create({
        name => 'DCOps',
        description => 'Datacenter Operations personnel',
        user_organization_roles => [ { user_id => $admin_id, role => 'admin' } ],
    });

    say '# Done.';
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
