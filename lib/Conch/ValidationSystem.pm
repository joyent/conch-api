package Conch::ValidationSystem;

use Mojo::Base -base, -signatures;
use Mojo::Util 'trim';
use Path::Tiny;
use Try::Tiny;
use Module::Runtime 'require_module';

has 'schema';
has 'log';

=pod

=head1 NAME

Conch::ValidationSystem

=head1 METHODS

=head2 check_validation_plans

Verifies that all validations mentioned in validation plans correspond to modules we actually
have available in Conch::Validation::*.

Validations not referenced by an active plan are ignored.

=cut

sub check_validation_plans ($self) {
    $self->log->debug('verifying all active validation plans');
    my $validation_plan_rs = $self->schema->resultset('validation_plan')
        ->active
        ->prefetch({ validation_plan_members => 'validation' });

    my %validation_modules;
    while (my $validation_plan = $validation_plan_rs->next) {
        ++$validation_modules{$_} foreach
            $self->check_validation_plan($validation_plan);
    }

    $self->log->debug('found '.scalar(keys %validation_modules).' valid validation modules');
    return scalar keys %validation_modules;
}

=head2 check_validation_plan

Verifies that a validation plan and its validations are all correct (correct
parent class, module attributes match database fields, etc).

Returns the name of all modules successfully loaded.

=cut

sub check_validation_plan ($self, $validation_plan) {
    my %validation_modules;
    my $valid_plan = 1;
    foreach my $validation ($validation_plan->validations) {
        if ($validation->deactivated) {
            $self->log->warn('validation id '.$validation->id
                .' "'.$validation->name.'" is inactive but is referenced by an active plan ("'
                .$validation_plan->name.'")');
            next;
        }

        my $module = $validation->module;

        try {
            require_module($module);
            if (not $module->isa('Conch::Validation')) {
                $self->log->error("$module must be a sub-class of Conch::Validation");
                $valid_plan = 0;
                return;
            }

            my $validator = $module->new;
            my $failed;

            foreach my $field (qw(version name description)) {
                if ($validation->$field ne trim($validator->$field)) {
                    $self->log->warn('"'.$field.'" field for validation id '.$validation->id
                        .' does not match value in '.$module
                        .' ("'.$validation->$field.'" vs "'.$validator->$field.'")');
                    $valid_plan = 0;
                    ++$failed;
                }
            }

            ++$validation_modules{$module} if not $failed;
        }
        catch {
            my $e = $_;
            $self->log->error('could not load '.$module
                .', used in validation plan "'.$validation_plan->name.'": '.$e);
            $valid_plan = 0;
        };
    }

    my $str = 'Validation plan id '.$validation_plan->id.' "'.$validation_plan->name.'" is ';
    if ($valid_plan) {
        $self->log->info($str.'valid');
    }
    else {
        $self->log->warn($str.'not valid');
    }

    return keys %validation_modules;
}

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
