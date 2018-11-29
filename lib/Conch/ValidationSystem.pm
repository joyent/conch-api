package Conch::ValidationSystem;

use Mojo::Base -base, -signatures;
use Mojo::Util 'trim';
use Path::Tiny;
use Try::Tiny;
use Module::Runtime 'require_module';
use List::Util 'all';

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
                return; # from try sub
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

            if (not $validator->category) {
                $self->log->warn("$module does not set a category");
                $valid_plan = 0;
                ++$failed;
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

        my @fields = qw(name version description category);
        if (not all { $validator->$_ } @fields) {
            $self->log->fatal("$module must define the " .
                join(', ', map { "'$_'" } @fields) . ' attributes');
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

=head2 run_validation

Runs the provided validation record against the provided device.
Creates and returns validation_result records, without writing them to the database.

All provided data objects can and should be read-only (fetched with a ro db handle).

Takes options as a hash:

    validation => $validation,      # required, a Conch::DB::Result::Validation object
    device => $device,              # required, a Conch::DB::Result::Device object
    data => $data,                  # required, a hashref of device report data

=cut

sub run_validation ($self, %options) {
    my $validation = delete $options{validation} || Carp::croak('missing validation');
    my $device = delete $options{device} || Carp::croak('missing device');
    my $data = delete $options{data} || Carp::croak('missing data');

    # FIXME! this is all awful and validators need to be rewritten to accept ro DBIC objects.
    my $location = Conch::Model::DeviceLocation->lookup($device->id);
    # FIXME: do we really allow running validations on unlocated hardware?
    my $hw_product_id =
          $location
        ? $location->target_hardware_product->id
        : $device->hardware_product_id;

    my $validator = Conch::Model::Validation->new(
        $validation->get_columns
    )->build_device_validation(
        Conch::Model::Device->new($device->get_columns),
        Conch::Model::HardwareProduct->lookup($hw_product_id),
        $location,
        +{ $device->device_settings_as_hash },
    );
    $validator->log($self->log);
    $validator->run($data);

    # Conch::Model::ValidationResult -> Conch::DB::Result::ValidationResult
    my $validation_result_rs = $self->schema->resultset('validation_result');
    my @validation_results = map {
        my $result = $_;
        $validation_result_rs->new_result({
            map { $_ => $result->$_ } qw(device_id hardware_product_id validation_id message hint status category component_id result_order),
        });
    } $validator->validation_results->@*;

    return @validation_results;
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
