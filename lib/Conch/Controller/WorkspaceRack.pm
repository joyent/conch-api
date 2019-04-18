package Conch::Controller::WorkspaceRack;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Role::Tiny::With;
with 'Conch::Role::MojoLog';

use Text::CSV_XS;
use Try::Tiny;
use List::Util 'reduce';

=pod

=head1 NAME

Conch::Controller::WorkspaceRack

=head1 METHODS

=head2 list

Get a list of racks for the current workspace (as specified by :workspace_id in the path).

Response uses the WorkspaceRackSummary json schema.

=cut

sub list ($c) {
    my $racks_rs = $c->stash('workspace_rs')
        ->related_resultset('workspace_racks')
        ->related_resultset('rack');

    my $device_health_rs = $racks_rs->search(
        { 'device.id' => { '!=' => undef } },
        {
            columns => { rack_id => 'rack.id' },
            select => [ { count => '*', -as => 'count' } ],
            join => { device_locations => 'device' },
            distinct => 1,  # group by all columns in final resultset
        },
    );

    my $invalid_rs = $device_health_rs->search(
        { 'device.validated' => undef },
        { '+columns' => { status => 'device.health' } },
    );

    my $valid_rs = $device_health_rs->search(
        { 'device.validated' => { '!=' => undef } },
    );

    # turn valid, invalid health data into a hash keyed by rack id:
    my %device_progress;
    foreach my $entry ($invalid_rs->hri->all, $valid_rs->hri->all) {
        # TODO: don't upper-case status values.
        $device_progress{$entry->{rack_id}}{uc($entry->{status} // 'VALID')} += $entry->{count};
    }

    my @rack_data = $racks_rs->as_subselect_rs->search(undef,
        {
            columns => {
                az => 'datacenter_room.az',
                id => 'rack.id',
                name => 'rack.name',
                role => 'rack_role.name',
                size => 'rack_role.rack_size',
            },
            join => [ qw(datacenter_room rack_role) ],
            collapse => 1,
        },
    )->hri->all;

    my $final_rack_data = reduce {
        push $a->{ delete $b->{az} }->@*, +{
            $b->%*,
            device_progress => $device_progress{ $b->{id} } // {},
        };
        $a;
    } +{}, @rack_data;

    $c->status(200, $final_rack_data);
}

=head2 find_rack

Chainable action that takes the 'rack_id' provided in the path and looks it up in the
database, stashing a resultset to access it as 'rack_rs'.

=cut

sub find_rack ($c) {
    my $rack_id = $c->stash('rack_id');
    my $rack_rs = $c->stash('workspace_rs')
        ->related_resultset('workspace_racks')
        ->related_resultset('rack')
        ->search({ 'rack.id' => $rack_id });

    if (not $rack_rs->exists) {
        $c->log->debug("Could not find rack $rack_id");
        return $c->status(404);
    }

    # store the simplified query to access the device, now that we've confirmed the user has
    # permission to access it.
    # No queries have been made yet, so you can add on more criteria or prefetches.
    $c->stash('rack_rs',
        $c->db_racks->search_rs({ 'rack.id' => $rack_id }));

    $c->log->debug("Found rack $rack_id");
    return 1;
}

=head2 get_layout

Get the layout of the current rack (as specified by :rack_id in the path).
Supports json, csv formats.

Response uses the WorkspaceRack json schema.

=cut

sub get_layout ($c) {

	my $format = $c->accepts('json', 'csv');

	if ($format eq 'json') {

        my $layout_rs = $c->stash('rack_rs')
            ->search(undef,
                {
                    columns => {
                        ( map {; $_ => "rack.$_" } qw(id name phase) ),
                        role => 'rack_role.name',
                        datacenter => 'datacenter_room.az',
                        'layout.rack_unit_start' => 'rack_layouts.rack_unit_start',
                        ( map {; "layout.$_" => "hardware_product.$_" } qw(alias id name) ),
                        'layout.vendor' => 'hardware_vendor.name',
                        'layout.size' => 'hardware_product_profile.rack_unit',
                        ( map {; "layout.device.$_" => "device.$_" } $c->schema->source('device')->columns ),
                    },
                    join => [
                        'rack_role',
                        'datacenter_room',
                        { rack_layouts => [
                            { device_location => 'device' },
                            { hardware_product => [ 'hardware_vendor', 'hardware_product_profile' ] },
                          ] },
                    ],
                    order_by => 'rack_layouts.rack_unit_start',
                },
            );

        my @raw_data = $layout_rs->hri->all;
        my $device_class = $c->db_devices->result_class;
        my $rsrc = $c->schema->source('device');

        my $layout = {
            ( map { $_ => $raw_data[0]->{$_} } qw(id name role datacenter phase) ),
            slots => [
                map {
                    my $device = delete $_->{layout}{device};
                    +{
                        $_->{layout}->%*,
                        occupant => $device ? +{
                            $device_class->inflate_result($rsrc, $device)->TO_JSON->%*,
                            rack_id => $c->stash('rack_id'),
                            rack_unit_start => $_->{layout}{rack_unit_start},
                        } : undef,
                    }
                } @raw_data
            ],
        };

        $c->log->debug('Found rack layouts for rack id '.$layout->{id});
        return $c->status(200, $layout);

	} elsif ($format eq 'csv') {

		my $layout_rs = $c->stash('rack_rs')
			->search(undef,
				{
					columns => {
						az => 'datacenter_room.az',
						rack_name => 'rack.name',
						rack_unit_start => 'rack_layouts.rack_unit_start',
						hardware_name => 'hardware_product.name',
						device_asset_tag => 'device.asset_tag',
						device_serial_number => 'device.id',
					},
					join => [
						'datacenter_room',
						{ rack_layouts => [
							'hardware_product',
							{ device_location => 'device' },
						  ] },
					],
					order_by => 'rack_layouts.rack_unit_start',
				},
			);

		# TODO: at a future time, this will be moved to a utility class
		# which will take in a resultset and list of header names and
		# generate a csv response.

		my @raw_data = $layout_rs->hri->all;

		# specify the desired order of the columns
		my @headers = qw(az rack_name rack_unit_start hardware_name device_asset_tag device_serial_number);

		my $csv_content;
		open my $fh, '>:encoding(UTF-8)', \$csv_content
			or die "could not open fh for writing to scalarref: $!";
		my $csv = Text::CSV_XS->new({ binary => 1, eol => $/ });
		$csv->column_names(@headers);
		$csv->print($fh, \@headers);
		$csv->print_hr($fh, $_) for @raw_data;
		close $fh or die "could not close $fh: $!";

		$c->log->debug('Found rack layouts for rack id '.$c->stash('rack_id'));

		$c->res->code(200);
		$c->respond_to(
			csv => { text => $csv_content },
		);
		return;
	}
	else {
		return $c->status(406, { error => "requested unknown format $format" });
	}
}

=head2 add

Add a rack to a workspace, unless it is the GLOBAL workspace, provided the rack
is assigned to the parent workspace of this one.

=cut

sub add ($c) {
    return $c->status(403) unless $c->is_workspace_admin;

    my $input = $c->validate_input('WorkspaceAddRack');
    return if not $input;

    my $rack_id = delete $input->{id};

    return $c->status(400, { error => 'Cannot modify GLOBAL workspace' })
        if $c->stash('workspace_rs')->get_column('name')->single eq 'GLOBAL';

    # note this only checks one layer up, rather than all the way up the hierarchy.
    if (not $c->stash('workspace_rs')
            ->related_resultset('parent_workspace')
            ->related_resultset('workspace_racks')
            ->related_resultset('rack')
            ->search({ 'rack.id' => $rack_id })->exists) {
        return $c->status(409,
            { error => "Rack '$rack_id' must be assigned in parent workspace to be assignable." },
        );
    }

    $c->db_workspace_racks->update_or_create({
        workspace_id => $c->stash('workspace_id'),
        rack_id => $rack_id,
    });

    # update rack with additional info, if provided.
    if (keys %$input) {
        my $rack = $c->db_racks->find($rack_id);
        $rack->set_columns($input);
        $rack->update({ updated => \'now()' }) if $rack->is_changed;
    }

    $c->status(303);
    $c->redirect_to($c->url_for('/workspace/'.$c->stash('workspace_id')."/rack/$rack_id"));
}

=head2 remove

Remove a rack from a workspace, unless it was implicitly assigned via a
datacenter room assignment

Requires 'admin' permissions on the workspace.

=cut

sub remove ($c) {
    return $c->status(400, { error => 'Cannot modify GLOBAL workspace' })
        if $c->stash('workspace_rs')->get_column('name')->single eq 'GLOBAL';

    my $rows_deleted = $c->db_workspaces
        ->and_workspaces_beneath($c->stash('workspace_id'))
        ->search_related('workspace_racks',
            { rack_id => $c->stash('rack_id') })
        ->delete;

    # 0 rows deleted -> 0E0 which is boolean truth, not false
    return $c->status(204) if $rows_deleted > 0;

    return $c->status(409, { error => 'Rack \''.$c->stash('rack_id')
        .'\' is not explicitly assigned to the workspace. It is assigned implicitly via a datacenter room assignment.',
    });
}

=head2 assign_layout

Assign a full or partial layout for a rack

Response returns the list of devices that were updated.

Response uses the WorkspaceRackLayoutUpdateResponse json schema.

=cut

sub assign_layout ($c) {
    my $input = $c->validate_input('WorkspaceRackLayoutUpdate');
    return if not $input;

    my $rack_id = $c->stash('rack_id');
    my @errors;

    try {
        $c->schema->txn_do(sub {
            foreach my $device_id (keys %$input) {
                try {
                    $c->db_device_locations->assign_device_location(
                        $device_id,
                        $rack_id,
                        $input->{$device_id},   # rack_unit_start
                    );
                }
                catch {
                    push @errors, $_;
                };
            }

            chomp @errors;
            die join('; ', @errors) if @errors;
        });
    }
    catch {
        if ($_ =~ /Rollback failed/) {
            local $@ = $_;
            die;    # propagate the error
        }
        $c->log->debug('aborted assign_layout transaction: ' . $_);
    };

    return $c->status(409, { error => join('; ', @errors) }) if @errors;

    # return the list of device_ids that were assigned
    $c->status(200, { updated => [ keys %$input ] });
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
