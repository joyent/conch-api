package Test::Conch::Fixtures;
use v5.26;
use warnings;

use Moo;
no Moo::sification;
extends 'DBIx::Class::EasyFixture';

use MooX::HandlesVia;
use namespace::autoclean;

=pod

=head1 NAME

Test::Conch::Fixtures

=head1 DESCRIPTION

Provides database fixtures for testing.

=head1 USAGE

    my $fixtures = Test::Conch::Fixtures->new(
        definitions => {
            fixture_1 => { ... },
            fixture_2 => { ... },
        },
    );

See L<Test::Conch/fixtures> for main usage.

=cut

my %canned_definitions = (
    # see DBIx::Class::EasyFixture::Tutorial for syntax.

    # groups
    legacy_datacenter => [
        'conch_user_global_workspace',
        '00-hardware',
        '01-hardware-profiles',
        '02-zpool-profiles',
        '03-test-datacenter',
    ],
    '00-hardware' => [qw(
        hardware_vendor_0
        hardware_vendor_1
        hardware_product_switch
        hardware_product_server_compute
        hardware_product_server_storage
    )],
    '01-hardware-profiles' => [qw(
        hardware_product_profile_switch
        hardware_product_profile_storage
        hardware_product_profile_compute
    )],
    '02-zpool-profiles' => [qw(
        zpool_profile_compute
        zpool_profile_storage
    )],
    '03-test-datacenter' => [qw(
        legacy_datacenter_rack_role_10u
        legacy_datacenter_region_1
        legacy_datacenter_room_1a
        legacy_datacenter_rack
        legacy_datacenter_rack_layout_1_2
        legacy_datacenter_rack_layout_3_6
        legacy_datacenter_rack_layout_7_10
    )],


    # individual definitions

    # also created via Test::ConchTmpDB::mk_tmp_db
    conch_user => {
        new => 'user_account',
        using => {
            name => 'conch',
            email => 'conch@conch.joyent.us',
            password_hash => '{CRYPT}$2a$04$h963P26i4rTMaVogvA2U7ePcZTYm2o0gfSHyxaUCZSuthkpg47Zbi',
            is_admin => 1,
        },
    },

    # also created by migration 0012.
    global_workspace => {
        new => 'workspace',
        using => {
            name => 'GLOBAL',
            description => 'Global workspace. Ancestor of all workspaces.',
        },
    },

    # also created via Test::ConchTmpDB::mk_tmp_db
    conch_user_global_workspace => {
        new => 'user_workspace_role',
        using => {
            role => 'admin',
            # cannot do this until I fix https://github.com/Ovid/dbix-class-easyfixture/issues/15
            # user_id => { conch_user => 'id' },
            # workspace_id => { global_workspace => 'id' },
        },
        requires => {
            conch_user => { our => 'user_id', their => 'id' },
            global_workspace => { our => 'workspace_id', their => 'id' },
        },
    },

    hardware_vendor_0 => {
        new => 'hardware_vendor',
        using => {
            name => 'DellBell',
        },
    },
    hardware_vendor_1 => {
        new => 'hardware_vendor',
        using => {
            name => 'SuperDuperMicro',
        },
    },

    hardware_product_switch => {
        new => 'hardware_product',
        using => {
            name => 'Switch',
            alias => 'Farce 10',
            prefix => 'F10',
            legacy_product_name => 'FuerzaDiaz',
        },
        requires => {
            hardware_vendor_0 => { our => 'hardware_vendor_id', their => 'id' },
        },
    },
    hardware_product_server_compute => {
        new => 'hardware_product',
        using => {
            name => '2-ssds-1-cpu',
            alias => 'Test Compute',
            prefix => 'HA',
            sku => '550-551-001',
            generation_name => 'Joyent-G1',
            legacy_product_name => 'Joyent-Compute-Platform',
        },
        requires => {
            hardware_vendor_0 => { our => 'hardware_vendor_id', their => 'id' },
        },
    },
    hardware_product_server_storage => {
        new => 'hardware_product',
        using => {
            name => '65-ssds-2-cpu',
            alias => 'Test Storage',
            prefix => 'MS',
            sku => '550-552-003',
            generation_name => 'Joyent-S1',
            legacy_product_name => 'Joyent-Storage-Platform',
        },
        requires => {
            hardware_vendor_1 => { our => 'hardware_vendor_id', their => 'id' },
        },
    },

    hardware_product_profile_switch => {
        new => 'hardware_product_profile',
        using => {
            purpose => 'TOR switch',
            bios_firmware => '9.10',
            cpu_num => 1,
            cpu_type => 'Intel Rangeley',
            dimms_num => 1,
            ram_total => 3,
            nics_num => 48,
            psu_total => 2,
            rack_unit => 1,
            usb_num => 0,
        },
        requires => {
            hardware_product_switch => { our => 'hardware_product_id', their => 'id' },
        },
    },
    hardware_product_profile_storage => {
        new => 'hardware_product_profile',
        using => {
            purpose => 'Manta Object Store',
            bios_firmware => 'American Megatrends Inc. 2.0a',
            cpu_num => 2,
            cpu_type => 'Intel(R) Xeon(R) CPU E5-2690 v4 @ 2.60GHz',
            dimms_num => 16,
            ram_total => 512,
            nics_num => 7,
            sas_num => 35,
            sas_size => 7452,
            ssd_num => 1,
            ssd_size => 93,
            ssd_slots => '0',
            psu_total => 2,
            rack_unit => 4,
            usb_num => 1,
        },
        requires => {
            hardware_product_server_storage => { our => 'hardware_product_id', their => 'id' },
            zpool_profile_storage => { our => 'zpool_id', their => 'id' },
        },
    },
    hardware_product_profile_compute => {
        new => 'hardware_product_profile',
        using => {
            purpose => 'General Compute',
            bios_firmware => 'Dell Inc. 2.2.5',
            cpu_num => 2,
            cpu_type => 'Intel(R) Xeon(R) CPU E5-2690 v4 @ 2.60GHz',
            dimms_num => 16,
            ram_total => 256,
            nics_num => 7,
            sas_num => 15,
            sas_size => 1118,
            ssd_num => 1,
            ssd_size => 93,
            ssd_slots => '0',
            psu_total => 2,
            rack_unit => 2,
            usb_num => 1,
        },
        requires => {
            hardware_product_server_compute => { our => 'hardware_product_id', their => 'id' },
            zpool_profile_compute => { our => 'zpool_id', their => 'id' },
        },
    },

    zpool_profile_compute => {
        new => 'zpool_profile',
        using => {
            name => '2-ssds-1-cpu',
            vdev_t => 'mirror',
            vdev_n => 7,
            disk_per => 2,
            spare => 1,
            log => 1,
            cache => 0,
        },
    },
    zpool_profile_storage => {
        new => 'zpool_profile',
        using => {
            name => '65-ssds-2-cpu',
            vdev_t => 'raidz2',
            vdev_n => 3,
            disk_per => 11,
            spare => 2,
            log => 1,
            cache => 0,
        },
    },

    legacy_datacenter_rack_role_10u => {
        new => 'datacenter_rack_role',
        using => {
            name => 'TEST_RACK_ROLE',
            rack_size => 10,
        },
    },
    legacy_datacenter_region_1 => {
        new => 'datacenter',
        using => {
            vendor => 'Test Vendor',
            vendor_name => 'Test Name',
            region => 'test-region-1',
            location => 'Testlandia, Testopolis',
        },
    },
    legacy_datacenter_room_1a => {
        new => 'datacenter_room',
        using => {
            az => 'test-region-1a',
            alias => 'TT1',
            vendor_name => 'TEST1.1',
        },
        requires => {
            legacy_datacenter_region_1 => { our => 'datacenter_id', their => 'id' },
        },
    },
    legacy_datacenter_rack => {
        new => 'datacenter_rack',
        using => {
            name => 'Test Rack',
        },
        requires => {
            legacy_datacenter_room_1a => { our => 'datacenter_room_id', their => 'id' },
            legacy_datacenter_rack_role_10u => { our => 'datacenter_rack_role_id', their => 'id' },
        },
    },
    legacy_datacenter_rack_layout_1_2 => {
        new => 'datacenter_rack_layout',
        using => {
            rack_unit_start => 1,
        },
        requires => {
            legacy_datacenter_rack => { our => 'rack_id', their => 'id' },
            hardware_product_server_compute => { our => 'hardware_product_id', their => 'id' },
        },
    },
    legacy_datacenter_rack_layout_3_6 => {
        new => 'datacenter_rack_layout',
        using => {
            rack_unit_start => 3,
        },
        requires => {
            legacy_datacenter_rack => { our => 'rack_id', their => 'id' },
            hardware_product_server_compute => { our => 'hardware_product_id', their => 'id' },
        },
    },
    legacy_datacenter_rack_layout_7_10 => {
        new => 'datacenter_rack_layout',
        using => {
            rack_unit_start => 7,
        },
        requires => {
            legacy_datacenter_rack => { our => 'rack_id', their => 'id' },
            hardware_product_server_storage => { our => 'hardware_product_id', their => 'id' },
        },
    },
);

# initialize definitions with those passed in, folded together with our defaults.
around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;

    my $args = $class->$orig(@_);

    return +{
        definitions => {
            %canned_definitions,
            (delete $args->{definitions} // +{})->%*,
        },
        %$args,
    },
};

=head2 add_definition

Add a new fixture definition.

=head2 get_definition

Used by DBIx::Class::Fixtures.

=head2 all_fixture_names

Used by DBIx::Class::Fixtures.

=cut

has definitions => (
    is => 'bare',
    handles_via => 'Hash',
    handles => {
        add_definition => 'set',
        get_definition => 'get',
        all_fixture_names => 'keys',
        _has_definition => 'exists',
    },
    required => 1,
);

before get_definition => sub {
    my ($self, $name) = @_;
    die "missing fixture definition for $name" if not $self->_has_definition($name);
};

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
