package Conch::Validation::HddSize;

use Mojo::Base 'Conch::Validation', -signatures;
use Mojo::JSON 'from_json';

use constant name        => 'hdd_size';
use constant version     => 1;
use constant category    => 'DISK';
use constant description => 'Check hard drive sizes';

sub validate ($self, $data) {
    my $hw_spec = from_json($self->hardware_product_specification // {});

    return if not $hw_spec->{disk_size};

    foreach my $disk_serial (keys $data->{disks}->%*) {
        my $drive_model = $data->{disks}{$disk_serial}{model};
        if (not $drive_model) {
            $self->fail('missing drive model for disk '.$disk_serial,
                component_id => $disk_serial);
            next;
        }

        # expected block_sz is indexed by disk 'model', falling back to '_default'.
        my $size_spec = $hw_spec->{disk_size}{$drive_model} // $hw_spec->{disk_size}{_default};
        if (not $size_spec) {
            $self->fail('missing size specification for model '.$drive_model,
                component_id => $disk_serial);
            next;
        }

        $self->register_result(
            got => $data->{disks}{$disk_serial}{block_sz},
            expected => $size_spec,
            component_id => $disk_serial,
        );
    }
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
