=head1 NAME

Conch::Controller::Orc::Device

=head1 METHODS

=cut

package Conch::Controller::Orc::Device;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Conch::Orc;
use Conch::Model::Device;


=head2 get_executions

Get all the Workflow::Executions associated with a device

=cut

sub get_executions ($c) {
	my $d = Conch::Model::Device->new->lookup($c->param('id'));
	return $c->status(404 => { error => "Device not found" })
		unless $d;

	my $ex = Conch::Orc::Workflow::Execution->many_from_device($d);
	my @v1 = map { $_->v1 } $ex->@*;
	$c->status(200 => \@v1);
}


=head2 get_latest_execution

Get the latest Workflow::Execution for a given device

=cut

sub get_latest_execution ($c) {
	my $d = Conch::Model::Device->new->lookup($c->param('id'));

	return $c->status(404 => { error => "Device not found" })
		unless $d;

	my $ex = Conch::Orc::Workflow::Execution->latest_from_device($d);

	return $c->status(404 => { error => "No status information" })
		unless $ex;

	$c->status(200 => $ex->v1_latest);
}


=head2 get_lifecycles

Get all Lifecycles for a given device

=cut

sub get_lifecycles ($c) {
	my $d = Conch::Model::Device->new->lookup($c->param('id'));

	return $c->status(404 => { error => "Device not found" })
		unless $d;

	my @many = map {
		$_->v1_cascade if $_
	} Conch::Orc::Lifecycle->many_from_device($d)->@*;

	$c->status(200 => \@many);
}


=head2 get_lifecycles_executions

Get a list of all the lifecycles and their associated executions for a given
device

=cut

sub get_lifecycles_executions ($c) {
	my $d = Conch::Model::Device->new->lookup($c->param('id'));

	return $c->status(404 => { error => "Device not found" })
		unless $d;

	my @many;
	foreach my $l (Conch::Orc::Lifecycle->many_from_device($d)->@*) {
		my @e;
		foreach my $w ($l->workflows->@*) {
			push @e, Conch::Orc::Workflow::Execution->new(
				device_id   => $d->id,
				workflow_id => $w->id,
			)->v1;
		}
		push @many, {
			lifecycle  => $l->v1_cascade,
			executions => \@e,
		};
	}

	$c->status(200 => \@many);
}

1;

__DATA__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.

=cut

