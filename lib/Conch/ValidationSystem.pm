package Conch::ValidationSystem;

use Mojo::Base -base, -signatures;
use Mojo::Util 'trim';
use Path::Tiny;

has 'schema';
has 'log';

=pod

=head1 NAME

Conch::ValidationSystem

=head1 METHODS

=head2 load_validations

Load all Conch::Validation::* sub-classes into the database.
Existing validation records will only be modified if attributes change.

Returns the number of new or changed validations loaded.

=cut

sub load_validations ($self) {
    my $num_loaded_validations = 0;

    $self->log->debug('loading modules under lib/Conch/Validation/');

    my $iterator = sub {
        my $filename = shift;
        return if not -f $filename;
        return if $filename !~ /\.pm$/; # skip swap files

        my $relative = $filename->relative('lib');
        my ($module) = $relative =~ s{/}{::}gr;
        $module =~ s/\.pm$//;
        $self->log->info("loading $module");
        require $relative;

        if (not $module->isa('Conch::Validation')) {
            $self->log->fatal("$module must be a sub-class of Conch::Validation");
            return;
        }

        my $validator = $module->new;

        if (not ($validator->name and $validator->version and $validator->description)) {
            $self->log->fatal("$module must define the 'name', 'version, and 'description' attributes");
            return;
        }

        if (my $validation_row = $self->schema->resultset('validation')->find({
                name => $validator->name,
                version => $validator->version,
            })) {
            $validation_row->set_columns({
                description => trim($validator->description),
                module => $module,
            });
            if ($validation_row->is_changed) {
                $validation_row->update({ updated => \'now()' });
                $num_loaded_validations++;
                $self->log->info("Updated entry for $module");
            }
        }
        else {
            $self->schema->resultset('validation')->create({
                name => $validator->name,
                version => $validator->version,
                description => trim($validator->description),
                module => $module,
            });
            $num_loaded_validations++;
            $self->log->info("Created entry for $module");
        }
    };

    path('lib/Conch/Validation')->visit($iterator, { recurse => 1 });

    return $num_loaded_validations;
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
