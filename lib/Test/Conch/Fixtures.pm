package Test::Conch::Fixtures;

use Moo;
no Moo::sification;
extends 'DBIx::Class::EasyFixture';

use experimental 'signatures';
use MooX::HandlesVia;
use List::Util qw(any pairmap);
use Scalar::Util 'blessed';
use Storable 'dclone';
use Authen::Passphrase::AcceptAll;
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
    '00-hardware' => [qw(
        hardware_vendor_0
        hardware_vendor_1
        hardware_product_switch
        hardware_product_compute
        hardware_product_storage
    )],

    # individual definitions

    super_user => {
        new => 'user_account',
        using => {
            name => 'conch',
            email => 'conch@conch.joyent.us',
            password => Authen::Passphrase::AcceptAll->new,
            is_admin => 1,
        },
    },
    ro_user => {
        new => 'user_account',
        using => {
            name => 'ro_user',
            email => 'ro_user@conch.joyent.us',
            password => Authen::Passphrase::AcceptAll->new,
            is_admin => 0,
        },
    },
    rw_user => {
        new => 'user_account',
        using => {
            name => 'rw_user',
            email => 'rw_user@conch.joyent.us',
            password => Authen::Passphrase::AcceptAll->new,
            is_admin => 0,
        },
    },
    admin_user => {
        new => 'user_account',
        using => {
            name => 'admin_user',
            email => 'admin_user@conch.joyent.us',
            password => Authen::Passphrase::AcceptAll->new,
            is_admin => 0,
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

    admin_user_global_workspace => {
        new => 'user_workspace_role',
        using => {
            role => 'admin',
            # cannot do this until I fix https://github.com/Ovid/dbix-class-easyfixture/issues/15
            # user_id => { admin_user => 'id' },
            # workspace_id => { global_workspace => 'id' },
        },
        requires => {
            admin_user => { our => 'user_id', their => 'id' },
            global_workspace => { our => 'workspace_id', their => 'id' },
        },
    },
    ro_user_global_workspace => {
        new => 'user_workspace_role',
        using => { role => 'ro' },
        requires => {
            ro_user => { our => 'user_id', their => 'id' },
            global_workspace => { our => 'workspace_id', their => 'id' },
        },
    },
    rw_user_global_workspace => {
        new => 'user_workspace_role',
        using => { role => 'rw' },
        requires => {
            rw_user => { our => 'user_id', their => 'id' },
            global_workspace => { our => 'workspace_id', their => 'id' },
        },
    },

    ro_user_organization => {
        new => 'user_organization_role',
        using => { role => 'admin' },
        requires => {
            ro_user => { our => 'user_id', their => 'id' },
            main_organization => { our => 'organization_id', their => 'id' },
        },
    },
    main_organization => {
        new => 'organization',
        using => {
            name => 'our first organization',
        },
    },

    hardware_vendor_0 => {
        new => 'hardware_vendor',
        using => {
            name => 'Hardware Vendor 0',
        },
    },
    hardware_vendor_1 => {
        new => 'hardware_vendor',
        using => {
            name => 'Hardware Vendor 1',
        },
    },

    hardware_product_switch => {
        new => 'hardware_product',
        using => {
            name => 'Switch',
            alias => 'Switch Vendor',
            prefix => 'F10',
            legacy_product_name => 'FuerzaDiaz',
            rack_unit_size => 1,
            sku => 'switch_sku',
            purpose => 'TOR switch',
            bios_firmware => '9.10',
            cpu_num => 1,
            cpu_type => 'Intel Rangeley',
            dimms_num => 1,
            ram_total => 3,
            nics_num => 48,
            usb_num => 0,
        },
        requires => {
            hardware_vendor_0 => { our => 'hardware_vendor_id', their => 'id' },
            validation_plan_basic => { our => 'validation_plan_id', their => 'id' },
        },
    },
    # this is a server, not a switch.
    hardware_product_compute => {
        new => 'hardware_product',
        using => {
            name => '2-ssds-1-cpu',
            alias => 'Test Compute',
            prefix => 'HA',
            sku => '550-551-001',
            generation_name => 'Joyent-G1',
            legacy_product_name => 'Joyent-Compute-Platform',
            rack_unit_size => 2,
            purpose => 'General Compute',
            bios_firmware => 'Dell Inc. 2.2.5',
            cpu_num => 2,
            cpu_type => 'Intel(R) Xeon(R) CPU E5-2690 v4 @ 2.60GHz',
            dimms_num => 16,
            ram_total => 256,
            nics_num => 7,
            sas_hdd_num => 15,
            sata_ssd_num => 1,
            usb_num => 1,
        },
        requires => {
            hardware_vendor_0 => { our => 'hardware_vendor_id', their => 'id' },
            validation_plan_basic => { our => 'validation_plan_id', their => 'id' },
        },
    },
    # this is a server, not a switch.
    hardware_product_storage => {
        new => 'hardware_product',
        using => {
            name => '65-ssds-2-cpu',
            alias => 'Test Storage',
            prefix => 'MS',
            sku => '550-552-003',
            generation_name => 'Joyent-S1',
            legacy_product_name => 'Joyent-Storage-Platform',
            rack_unit_size => 4,
            purpose => 'Manta Object Store',
            bios_firmware => 'American Megatrends Inc. 2.0a',
            cpu_num => 2,
            cpu_type => 'Intel(R) Xeon(R) CPU E5-2690 v4 @ 2.60GHz',
            dimms_num => 16,
            ram_total => 512,
            nics_num => 7,
            sas_hdd_num => 35,
            sata_ssd_num => 1,
            usb_num => 1,
        },
        requires => {
            hardware_vendor_1 => { our => 'hardware_vendor_id', their => 'id' },
            validation_plan_basic => { our => 'validation_plan_id', their => 'id' },
        },
    },

    device_HAL => {
        new => 'device',
        using => {
            serial_number => 'HAL',
            health => 'unknown',
        },
        requires => {
            hardware_product_compute => { our => 'hardware_product_id', their => 'id' },
        },
    },

    validation_plan_basic => {
        new => 'validation_plan',
        using => {
            name => 'basic validation plan',
            description => 'whee',
        },
    },
);

=head1 METHODS

=head2 generate_set

Generates new fixture definition(s). Adds them to the internal definition list, but does not
load them to the database.

Available sets:

=over 4

=item * workspace_room_rack_layout
a new workspace under GLOBAL, with a datacenter_room,
rack, and a layout suitable for various hardware. Takes a single integer for uniqueness.

=back

=cut

sub generate_set ($self, $set_name, @args) {
    my %definitions;

    if ($set_name eq 'workspace_room_rack_layout') {
        my $num = shift(@args) // die 'need a unique integer';
        # XXX TODO: rewrite this using $self->generate_definitions(
        #   ...
        # );
        %definitions = (
            "sub_workspace_$num" => {
                new => 'workspace',
                using => { name => "sub_ws_$num" },
                requires => { global_workspace => { our => 'parent_workspace_id', their => 'id' } },
            },
            "ro_user_sub_workspace_${num}_ro" => {
                new => 'user_workspace_role',
                using => { role => 'ro' },
                requires => {
                    ro_user => { our => 'user_id', their => 'id' },
                    "sub_workspace_$num" => { our => 'workspace_id', their => 'id' },
                },
            },
            "datacenter_$num" => {
                new => 'datacenter',
                using => {
                    vendor => 'Acme Corp',
                    region => "region_$num",
                    location => 'Earth',
                },
            },
            "datacenter_room_${num}a" => {
                new => 'datacenter_room',
                using => {
                    az => "room-${num}a",
                    alias => "room ${num}a",
                },
                requires => {
                    "datacenter_$num" => { our => 'datacenter_id', their => 'id' },
                    # this is a hack: should be able to specify requirements without copying values.
                    global_workspace => { our => 'vendor_name', their => 'name' },
                },
            },
            rack_role_42u => {
                new => 'rack_role',
                using => {
                    name => 'rack_role 42U',
                    rack_size => 42,
                },
            },
            "workspace_rack_${num}a" => {
                new => 'workspace_rack',
                using => {},
                requires => {
                    "rack_${num}a" => { our => 'rack_id', their => 'id' },
                    "sub_workspace_$num" => { our => 'workspace_id', their => 'id' },
                },
            },
            "rack_${num}a" => {
                new => 'rack',
                using => { name => "rack ${num}a" },
                requires => {
                    "datacenter_room_${num}a" => { our => 'datacenter_room_id', their => 'id' },
                    rack_role_42u => { our => 'rack_role_id', their => 'id' },
                    # declare dependency for the all_racks_in_global_workspace trigger to run
                    # This is a hack: should be able to specify requirements without copying values.
                    global_workspace => { our => 'asset_tag', their => 'name' },
                },
            },
            "rack_${num}a_layout_1_2" => {
                new => 'rack_layout',
                using => {
                    rack_unit_start => 1,
                },
                requires => {
                    "rack_${num}a" => { our => 'rack_id', their => 'id' },
                    hardware_product_compute => { our => 'hardware_product_id', their => 'id' },
                },
            },
            "rack_${num}a_layout_3_6" => {
                new => 'rack_layout',
                using => {
                    rack_unit_start => 3,
                },
                requires => {
                    "rack_${num}a" => { our => 'rack_id', their => 'id' },
                    hardware_product_storage => { our => 'hardware_product_id', their => 'id' },
                },
            },
            "rack_${num}a_layout_11_14" => {
                new => 'rack_layout',
                using => {
                    rack_unit_start => 11,
                },
                requires => {
                    "rack_${num}a" => { our => 'rack_id', their => 'id' },
                    hardware_product_storage => { our => 'hardware_product_id', their => 'id' },
                },
            },
            "__additional_deps_workspace_room_rack_layout_${num}a" => [
                'hardware_product_compute',
                'hardware_product_storage',
            ],
        );
    }
    else {
        die "unrecognized fixture set name $set_name";
    }

    # add the definitions, if they do not yet exist.
    foreach my $fixture_name (keys %definitions) {
        $self->add_definition($fixture_name => $definitions{$fixture_name})
            if not $self->_has_definition($fixture_name);
    }
    return keys %definitions;
}

=head2 generate_definitions

Generates fixture definition(s) using generic data, and any necessary dependencies. Uses a
unique number to generate unique fixture names. Not-nullable fields are filled in with
sensible defaults, but all may be overridden.

Requires data format:

    fixture_type => { field data.. },
    ...,

C<fixture_type> is usually a table name, but might be pluralized or be something special. See
L</_generate_definition>.

=cut

sub generate_definitions ($self, $unique_num, %specification) {
    %specification = (dclone \%specification)->%*;
    my @requested = pairmap { [ $a, $unique_num, $b ] } %specification;

    my (%definitions, @processed);

    # this list will be progressively added to, so we do not use foreach.
    while (my $req = shift @requested) {
        my ($name, $num, $spec) = $req->@*;
        next if any { $_->[0] eq $name and $_->[1] eq $num } @processed;

        my ($definition, @dependencies) = $self->_generate_definition($name, $num, $spec);

        @definitions{keys $definition->%*} = values $definition->%*;
        push @requested, @dependencies;
        push @processed, [ $name, $num ];
    }

    # add the definitions, if they do not yet exist.
    foreach my $fixture_name (keys %definitions) {
        $self->add_definition($fixture_name => $definitions{$fixture_name})
            if not $self->_has_definition($fixture_name);
    }
    return keys %definitions;
}

=head2 _generate_definition

Data used in L</generate_definitions>. Returns a fixture definition as well as a list of other
recognized fixture types that must also be turned into fixtures to satisfy dependencies.

C<num> must be a value that is unique to the set of fixtures being generated; many fixtures
will refer to each other using this number as part of their name.

C<specification> is usually a hashref but might be a listref depending on the fixture type.

=cut

sub _generate_definition ($self, $fixture_type, $num, $specification) {
    if ($fixture_type eq 'device_settings') {
        my $letter = 'a';
        my $device_spec = delete $specification->{device} // {};
        return +{
            map +(
                "device_setting_$num".$letter++ => +{
                    new => 'device_setting',
                    using => {
                        name => $_,
                        value => $specification->{$_},
                    },
                    requires => { "device_$num" => { our => 'device_id', their => 'id' } },
                }
            ), keys $specification->%*
        },
        [ 'device', $num, $device_spec ];
    }
    elsif ($fixture_type eq 'device') {
        my $hw_spec = delete $specification->{hardware_product} // {};
        my $location_spec = delete $specification->{device_location};
        my $setting_specs = delete $specification->{device_settings};
        return +{
            "device_$num" => {
                new => 'device',
                using => {
                    serial_number => "DEVICE_$num",
                    health => 'unknown',
                    ($specification // {})->%*,
                },
                exists $specification->{hardware_product_id} ? () : (
                requires => {
                    "hardware_product_$num" => { our => 'hardware_product_id', their => 'id' },
                }),
            },
        },
        exists $specification->{hardware_product_id} ? () : [ 'hardware_product', $num, $hw_spec ],
        $location_spec ? [ 'device_location', $num, $location_spec ] : (),
        $setting_specs ? [ 'device_settings', $num, $setting_specs ] : ();
    }
    elsif ($fixture_type eq 'device_location') {
        $specification //= {};
        my $device_spec = delete $specification->{device} // {};
        my $rack_spec = delete $specification->{rack} // {};
        my $rack_unit_start = delete $specification->{rack_unit_start};
        my $layout_spec = delete $specification->{rack_layout} // {};
        return +{
            "device_location_$num" => {
                new => 'device_location',
                using => {
                    $specification->%*,
                },
                requires => {
                    "device_$num" => { our => 'device_id', their => 'id' },
                    "rack_$num" => { our => 'rack_id', their => 'id' },
                    "rack_layout_${num}_ru$rack_unit_start" => { our => 'rack_unit_start', their => 'rack_unit_start' },
                },
            },
        },
        [ 'device', $num, $device_spec ],
        [ 'rack', $num, $rack_spec ],
        [ 'rack_layout', $num, { $layout_spec->%*, rack_unit_start => $rack_unit_start } ];
    }
    elsif ($fixture_type eq 'rack_layout') {
        # note that we name our hardware_products carefully so we do not reuse any that might
        # be created for devices.
        my $hw_spec = delete $specification->{hardware_product} // {};
        my $rack_spec = delete $specification->{rack} // {};
        my $rack_unit_start = $specification->{rack_unit_start} // $num;
        my ($long_num, $short_num) =
            ($num =~ /^(\d+)_ru$rack_unit_start$/ ? ($num, $1)
                                                  : ($num.'_ru'.$rack_unit_start, $num));
        return +{
            "rack_layout_$long_num" => +{
                new => 'rack_layout',
                using => { rack_unit_start => $rack_unit_start, $specification->%* },
                requires => {
                    "rack_$short_num" => { our => 'rack_id', their => 'id' },
                    "hardware_product_$long_num" => { our => 'hardware_product_id', their => 'id' },
                },
            }
        },
        [ 'rack', $short_num, $rack_spec ],
        [ 'hardware_product', $long_num, $hw_spec ];
    }
    elsif ($fixture_type eq 'rack_layouts') {
        $specification //= [ { rack_unit_start => $num } ];
        return {}, map [ 'rack_layout', "${num}_ru".$_->{rack_unit_start}, $_ ], $specification->@*;
    }
    elsif ($fixture_type eq 'rack') {
        return +{
            "rack_$num" => {
                new => 'rack',
                using => {
                    name => "rack_$num",
                    ($specification // {})->%*,
                },
                requires => {
                    "datacenter_room_$num" => { our => 'datacenter_room_id', their => 'id' },
                    "rack_role_$num" => { our => 'rack_role_id', their => 'id' },
                    # declare dependency for the all_racks_in_global_workspace trigger to run
                    # This is a hack: should be able to specify requirements without copying values.
                    global_workspace => { our => 'asset_tag', their => 'name' },
                },
            },
        },
        [ 'datacenter_room', $num, {} ], [ 'rack_role', $num, {} ];
    }
    elsif ($fixture_type eq 'hardware_product') {
        my $vendor_spec = delete $specification->{hardware_vendor} // {};
        return +{
            "hardware_product_$num" => {
                new => 'hardware_product',
                using => {
                    name => "hardware_product_$num",
                    alias => "hardware_product_alias_$num",
                    sku => "hardware_product_sku_$num",
                    rack_unit_size => 42,
                    purpose => 'none',
                    bios_firmware => 'none',
                    cpu_num => 0,
                    cpu_type => 'blue',
                    dimms_num => 0,
                    ram_total => 0,
                    nics_num => 0,
                    usb_num => 0,
                    ($specification // {})->%*,
                },
                requires => {
                    "hardware_vendor_$num" => { our => 'hardware_vendor_id', their => 'id' },
                    "validation_plan_$num" => { our => 'validation_plan_id', their => 'id' },
                },
            },
        },
        [ 'hardware_vendor', $num, $vendor_spec ],
        [ 'validation_plan', $num, {} ];
    }
    elsif ($fixture_type eq 'datacenter_room') {
        return +{
            "datacenter_room_$num" => {
                new => 'datacenter_room',
                using => {
                    az => "datacenter_room_az_$num",
                    alias => "room alias $num",
                    ($specification // {})->%*,
                },
                requires => {
                    "datacenter_$num" => { our => 'datacenter_id', their => 'id' },
                },
            },
        },
        [ 'datacenter', $num, {} ];
    }
    elsif ($fixture_type eq 'rack_role') {
        return +{
            "rack_role_$num" => {
                new => 'rack_role',
                using => {
                    name => "rack_role_$num",
                    rack_size => 42,
                    ($specification // {})->%*,
                },
            },
        };
    }
    elsif ($fixture_type eq 'datacenter') {
        return +{
            "datacenter_$num" => {
                new => 'datacenter',
                using => {
                    vendor => 'vendor',
                    region => 'region_'.$num,
                    location => 'location',
                    ($specification // {})->%*,
                },
            },
        };
    }
    elsif ($fixture_type eq 'hardware_vendor') {
        return +{
            "hardware_vendor_$num" => {
                new => 'hardware_vendor',
                using => {
                    name => "hardware_vendor_$num",
                    ($specification // {})->%*,
                },
            },
        };
    }
    elsif ($fixture_type eq 'user_account') {
        return +{
            "user_account_$num" => {
                new => 'user_account',
                using => {
                    name => "user_$num",
                    email => "user_${num}\@conch.joyent.us",
                    password => Authen::Passphrase::AcceptAll->new,
                    ($specification // {})->%*,
                },
            },
        };
    }
    elsif ($fixture_type eq 'workspace') {
        return +{
            "workspace_$num" => {
                new => 'workspace',
                using => {
                    name => "workspace_$num",
                    ($specification // {})->%*,
                },
            },
        };
    }
    elsif ($fixture_type eq 'organization') {
        return +{
            "organization_$num" => {
                new => 'organization',
                using => {
                    name => "organization_$num",
                    ($specification // {})->%*,
                },
            },
        };
    }
    elsif ($fixture_type eq 'build') {
        return +{
            "build_$num" => {
                new => 'build',
                using => {
                    name => "build_$num",
                    ($specification // {})->%*,
                },
            },
        };
    }
    elsif ($fixture_type eq 'validation_plan') {
        return +{
            "validation_plan_$num" => {
                new => 'validation_plan',
                using => {
                    name => "validation_plan_$num",
                    description => "validation_plan_$num description",
                    ($specification // {})->%*,
                },
            },
        };
    }
    else {
        die 'unrecognized fixture type '.$fixture_type;
    }
}


# initialize definitions with those passed in, folded together with our defaults.
around BUILDARGS => sub ($orig, $class, @args) {
    my $args = $class->$orig(@args);

    return +{
        definitions => {
            %canned_definitions,
            (delete $args->{definitions} // +{})->%*,
        },
        $args->%*,
    },
};

=head2 add_definition

Add a new fixture definition.

=head2 get_definition

Used by L<DBIx::Class::Fixtures>.

=head2 all_fixture_names

Used by L<DBIx::Class::Fixtures>.

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

before get_definition => sub ($self, $name) {
    die "missing fixture definition for $name" if not $self->_has_definition($name);
};

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
