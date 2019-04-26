package Conch::ValidationSystem;

use Mojo::Base -base, -signatures;
use Mojo::Util 'trim';
use Path::Tiny;
use Try::Tiny;
use Module::Runtime 'require_module';
use List::Util qw(all reduce);
use Mojo::JSON 'from_json';

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
    if ($validation_plan->deactivated) {
        $self->log->warn('validation plan id '.$validation_plan->id
            .' "'.$validation_plan->name.'" is inactive');
        return;
    }

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

            my $failed;

            foreach my $field (qw(version name description)) {
                if ($validation->$field ne trim($module->$field)) {
                    $self->log->warn('"'.$field.'" field for validation id '.$validation->id
                        .' does not match value in '.$module
                        .' ("'.$validation->$field.'" vs "'.$module->$field.'")');
                    $valid_plan = 0;
                    ++$failed;
                }
            }

            if (not $module->category) {
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

        my @fields = qw(name version description category);
        if (not all { $module->$_ } @fields) {
            $self->log->fatal("$module must define the " .
                join(', ', map "'$_'", @fields).' attributes');
            return;
        }

        if (my $validation_row = $self->schema->resultset('validation')->search({
                name => $module->name,
                version => $module->version,
            })->single) {
            $validation_row->set_columns({
                description => trim($module->description),
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
                name => $module->name,
                version => $module->version,
                description => trim($module->description),
                module => $module,
            });
            $num_loaded_validations++;
            $self->log->info("Created entry for $module");
        }
    };

    path('lib/Conch/Validation')->visit($iterator, { recurse => 1 });

    return $num_loaded_validations;
}

=head2 run_validation_plan

Runs the provided validation_plan against the provided device.

All provided data objects can and should be read-only (fetched with a ro db handle).

If C<< no_save_db => 1 >> is passed, the validation records are returned (along with the
overall result status), without writing them to the database.  Otherwise, a validation_state
record is created and validation_result records saved with deduplication logic applied.

Takes options as a hash:

    validation_plan => $plan,       # required, a Conch::DB::Result::ValidationPlan object
    device => $device,              # required, a Conch::DB::Result::Device object
    device_report => $report,       # optional, a Conch::DB::Result::DeviceReport object
                                    # (required if no_save_db is false)
    data => $data,                  # optional, a hashref of device report data; required if
                                    # device_report is not provided
    no_save_db => 0|1               # optional, defaults to false

=cut

sub run_validation_plan ($self, %options) {
    my $validation_plan = delete $options{validation_plan} || Carp::croak('missing validation plan');
    my $device = delete $options{device} || Carp::croak('missing device');

    my $device_report = delete $options{device_report};
    Carp::croak('missing device report') if not $device_report and not $options{no_save_db};

    my $data = delete $options{data};
    $data //= from_json($device_report->report) if $device_report;
    Carp::croak('missing data or device report') if not $data;

    my $validation_rs = $validation_plan
        ->related_resultset('validation_plan_members')
        ->related_resultset('validation')
        ->active;

    my @validation_results;
    my $validation_result_rs = $self->schema->resultset('validation_result');
    while (my $validation = $validation_rs->next) {
        my $validator = $validation->module->new(
            log              => $self->log,
            device           => $device,
        );

        $validator->run($data);

        my $result_order = 0;
        push @validation_results, map
            $validation_result_rs->new_result({
                # each time a ValidationResult is created, increment order value
                # post-assignment. This allows us to distinguish between multiples
                # of similar results
                result_order        => $result_order++,
                validation_id       => $validation->id,
                device_id           => $device->id,
                hardware_product_id => $validator->hardware_product->id,
                $_->%{qw(message hint status category component_id)},
            }),
            $validator->validation_results;
    }

    # maybe no validations ran? this is a problem.
    if (not @validation_results) {
        $self->log->warn('validations did not produce a result');
        return;
    }

    my $status = reduce {
        $a eq 'error' || $b eq 'error' ? 'error'
      : $a eq 'fail' || $b eq 'fail' ? 'fail'
      : $a eq 'processing' || $b eq 'processing' ? 'processing'
      : $a; # pass
    } map $_->status, @validation_results;

    return ($status, @validation_results) if $options{no_save_db};

    return $self->schema->resultset('validation_state')->create({
        device_id => $device->id,
        device_report_id => $device_report->id,
        validation_plan_id => $validation_plan->id,
        status => $status,
        completed => \'now()',
        # provided column data is used to determine if these result(s) already exist in the db,
        # and they are reused if so, otherwise they are inserted
        validation_state_members => [ map +{ validation_result => $_ }, @validation_results ],
    });
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

    my $validator = $validation->module->new(
        log              => $self->log,
        device           => $device,
    );
    $validator->run($data);

    my $result_order = 0;
    my $validation_result_rs = $self->schema->resultset('validation_result');
    my @validation_results = map
        $validation_result_rs->new_result({
            # each time a ValidationResult is created, increment order value
            # post-assignment. This allows us to distinguish between multiples
            # of similar results
            result_order        => $result_order++,
            validation_id       => $validation->id,
            device_id           => $device->id,
            hardware_product_id => $validator->hardware_product->id,
            $_->%{qw(message hint status category component_id)},
        }),
        $validator->validation_results;

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
