package Conch::Controller::DatacenterRackRole;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Role::Tiny::With;
with 'Conch::Role::MojoLog';

=pod

=head1 NAME

Conch::Controller::DatacenterRackRole

=head1 METHODS

=head2 find_rack_role

Supports rack role lookups by uuid and name.

=cut

sub find_rack_role ($c) {
    return $c->status(403) unless $c->is_system_admin;

    my $rack_role;
    if ($c->stash('rack_role_id_or_name') =~ /^(.+?)\=(.+)$/) {
        my ($key, $value) = ($1, $2);
        if ($key ne 'name') {
            $c->log->warn("Unknown identifier '$key'");
            return $c->status(404 => { error => 'Not found' });
        }

        $c->log->debug("Looking up datacenter rack role using identifier '$key'");
        $rack_role = $c->db_datacenter_rack_roles->find({ name => $value });
    } else {
        $c->log->debug('looking up datacenter rack role by id');
        $rack_role = $c->db_datacenter_rack_roles->find($c->stash('rack_role_id_or_name'));
    }

    if (not $rack_role) {
        $c->log->debug('Failed to find datacenter rack role');
        return $c->status(404 => { error => 'Not found' });
    }

    $c->log->debug('Found datacenter rack role '.$rack_role->id);
    $c->stash('rack_role' => $rack_role);
    return 1;
}

=head2 create

Create a new rack role.

=cut

sub create ($c) {
    return $c->status(403) unless $c->is_system_admin;
    my $input = $c->validate_input('RackRoleCreate');
    return if not $input;

    if ($c->db_datacenter_rack_roles->search({ name => $input->{name} })->exists) {
        $c->log->debug("Name conflict on '".$input->{name}."'");
        return $c->status(400 => { error => 'name is already taken' });
    }

    my $rack_role = $c->db_datacenter_rack_roles->create($input);
    $c->log->debug('Created datacenter rack role '.$rack_role->id);
    $c->status(303 => '/rack_role/'.$rack_role->id);
}

=head2 get

Get a single rack role.

Response uses the RackRole json schema.

=cut

sub get ($c) {
    return $c->status(403) unless $c->is_system_admin;
    $c->status(200, $c->stash('rack_role'));
}

=head2 get_all

Get all rack roles.

Response uses the RackRoles json schema.

=cut

sub get_all ($c) {
    return $c->status(403) unless $c->is_system_admin;

    my @rack_roles = $c->db_datacenter_rack_roles->all;
    $c->log->debug('Found '.scalar(@rack_roles).' datacenter rack roles');

    $c->status(200 => \@rack_roles);
}

=head2 update

Modify an existing rack role.

=cut

sub update ($c) {
    my $input = $c->validate_input('RackRoleUpdate');
    return if not $input;

    if ($input->{name}) {
        if ($c->db_datacenter_rack_roles->search({ name => $input->{name} })->exists) {
            $c->log->debug("Name conflict on '".$input->{name}."'");
            return $c->status(400 => { error => 'name is already taken' });
        }
    }

    # prohibit shrinking rack_size if there are layouts that extend beyond it
    if ($input->{rack_size}) {
        my $rack_rs = $c->stash('rack_role')->self_rs
            ->related_resultset('datacenter_racks');

        while (my $rack = $rack_rs->next) {
            my %assigned_rack_units = map { $_ => 1 }
                $rack->self_rs->assigned_rack_units;
            my @assigned_rack_units = sort { $a <=> $b } keys %assigned_rack_units;

            if (my @out_of_range = grep { $_ > $input->{rack_size} } @assigned_rack_units) {
                $c->log->debug('found layout used by rack_role id '.$c->stash('rack_role')->id
                    .' that has assigned rack_units greater requested new rack_size of '
                    .$input->{rack_size}.': ', join(', ', @out_of_range));
                return $c->status(400 => { error => 'cannot resize rack_role: found an assigned rack layout that extends beyond the new rack_size' });
            }
        }
    }

    $c->stash('rack_role')->update($input);
    $c->log->debug('Updated datacenter rack role '.$c->stash('rack_role')->id);
    $c->status(303 => '/rack_role/'.$c->stash('rack_role')->id);
}

=head2 delete

Delete a rack role.

=cut

sub delete ($c) {
    $c->stash('rack_role')->delete;
    $c->log->debug('Deleted datacenter rack role '.$c->stash('rack_role')->id);
    return $c->status(204);
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
