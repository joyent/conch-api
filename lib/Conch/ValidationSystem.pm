package Conch::ValidationSystem;

use Mojo::Base -base, -signatures;
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
                .' "'.$validation->name.'" version '.$validation->version
                .' is inactive but is referenced by an active plan ("'
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
                if ($validation->$field ne $module->$field) {
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
Existing validation records will not be modified if attributes change -- instead, existing
records will be deactivated and new records will be created to reflect the updated data.

Returns a tuple: the number of validations that were deactivated, and the number of new
validation rows that were created.

This method is poorly-named: it should be 'create_validations'.

=cut

sub load_validations ($self) {
    my ($num_deactivated, $num_created) = (0, 0);

    $self->log->debug('loading modules under lib/Conch/Validation/');
    my $validation_rs = $self->schema->resultset('validation');
    my @modules;

    my $iterator = sub {
        my $filename = shift;
        return if not -f $filename;
        return if $filename !~ /\.pm$/; # skip swap files

        my $relative = $filename->relative('lib');
        my ($module) = $relative =~ s{/}{::}gr;
        $module =~ s/\.pm$//;
        push @modules, $module;

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

        # if the active validation row exactly matches the code, we have nothing to change
        return if $validation_rs->active
            ->search({
                name => $module->name,
                version => $module->version,
                description => $module->description,
                module => $module,
            })->exists;

        if (my $existing_validation = $validation_rs->active->search({ module => $module })->single) {
            if ($existing_validation->name eq $module->name and $existing_validation->version == $module->version) {
                # if we just log an error and return, it may not be obvious to the operator that
                # something bad has happened... and the old validation row would stay active
                # and cause more problems downstream
                die 'cannot create new row for validation named ', $existing_validation->name,
                    ', as there is already a row with its name and version ',
                    '(did you forget to increment the version in ', $module, '?)';
            }

            # deactivate all existing rows for this module
            my $deactivated = $validation_rs->active->search({ module => $module })->deactivate;
            $num_deactivated += $deactivated;
            $self->log->info('deactivated existing validation row for '.$module) if $deactivated > 0;
        }

        # create a new row with current data (this will explode with a unique constraint
        # violation if the version was not incremented)
        $validation_rs->create({
            name => $module->name,
            version => $module->version,
            description => $module->description,
            module => $module,
        });
        $num_created += 1;
        $self->log->info('created validation row for '.$module);
    };

    path('lib/Conch/Validation')->visit($iterator, { recurse => 1 });

    my $old_validations_rs = $validation_rs->active->search({ module => { -not_in => \@modules } });
    if ($old_validations_rs->exists) {
        $self->log->info('deactivating validation for no-longer-present modules: '
            .join(', ', $old_validations_rs->get_column('module')->all));
        $num_deactivated += $old_validations_rs->deactivate;
    }

    return ($num_deactivated, $num_created);
}

=head2 update_validation_plans

Deactivate and/or create validation records for all validation modules currently present, then
updates validation plan membership to reference the newest versions of the validations it
previously had as members.

That is: does whatever is necessary after a code deployment to ensure that validation plans
continue to run validations pointing to the same code modules.

=cut

sub update_validation_plans ($self) {
    my $validation_plan_rs = $self->schema->resultset('validation_plan');

    # deactivates old validation rows; creates new ones in their place
    # note that if a conflict is found, this sub will die.
    my ($num_deactivated, $num_created) = $self->load_validations;

    # now get the updated list of all active validations by module name...
    my %validations = map +($_->module => $_), $self->schema->resultset('validation')->active->all;

    $validation_plan_rs = $validation_plan_rs
        ->active
        ->prefetch({ validation_plan_members => 'validation' });

    while (my $plan = $validation_plan_rs->next) {
        my (%existing_active_validations, @add_active_validations);
        foreach my $member ($plan->validation_plan_members) {
            my $existing_validation = $member->validation;

            if ($existing_validation->deactivated) {
                $self->log->info('validation plan '.$plan->name.' has a deactivated validation ('
                    .$existing_validation->name.' version '.$existing_validation->version
                    .'): removing');
                $member->delete;

                if (my $new_validation = $validations{$existing_validation->module}) {
                    push @add_active_validations, $new_validation;
                }
            }
            else {
                $existing_active_validations{$existing_validation->module} = $existing_validation;
            }
        }

        # now we have a list of active validations we want.  add any that aren't already present.
        foreach my $want_validation (@add_active_validations) {
            next if $existing_active_validations{$want_validation->module};
            $self->log->info('adding '.$want_validation->name.' version '
                .$want_validation->version.' to validation plan '.$plan->name);
            $plan->add_to_validations($want_validation);
        }
    }
}

=head2 run_validation_plan

Runs the provided validation_plan against the provided device.

All provided data objects can and should be read-only (fetched with a ro db handle).

If C<< no_save_db => 1 >> is passed, the validation records are returned (along with the
overall result status), without writing them to the database. Otherwise, a validation_state
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

        push @validation_results, map
            $validation_result_rs->new_result({
                validation_id       => $validation->id,
                device_id           => $device->id,
                hardware_product_id => $validator->hardware_product->id,
                $_->%{qw(message hint status category component)},
            }),
            $validator->validation_results;

        $self->log->debug('validation '.$validation->name.' returned no results for device id '.$device->id)
            if not $validator->validation_results;
    }

    # maybe no validations ran? this is a problem.
    if (not @validation_results) {
        $self->log->warn('validations did not produce a result');
        return;
    }

    my $status = reduce {
        $a eq 'error' || $b eq 'error' ? 'error'
      : $a eq 'fail' || $b eq 'fail' ? 'fail'
      : $a; # pass
    } map $_->status, @validation_results;

    return ($status, @validation_results) if $options{no_save_db};

    $self->log->debug('recording validation status '.$status.' with '
        .(scalar @validation_results).' results for device id '.$device->id);

    my $result_order = 0;
    return $self->schema->resultset('validation_state')->create({
        device_id => $device->id,
        device_report_id => $device_report->id,
        validation_plan_id => $validation_plan->id,
        status => $status,
        completed => \'now()',
        # provided column data is used to determine if these result(s) already exist in the db,
        # and they are reused if so, otherwise they are inserted
        validation_state_members => [ map +{
            result_order => $result_order++,
            validation_result => $_,
        }, @validation_results ],
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

    my $validation_result_rs = $self->schema->resultset('validation_result');
    my @validation_results = map
        $validation_result_rs->new_result({
            validation_id       => $validation->id,
            device_id           => $device->id,
            hardware_product_id => $validator->hardware_product->id,
            $_->%{qw(message hint status category component)},
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
one at L<http://mozilla.org/MPL/2.0/>.

=cut
# vim: set ts=4 sts=4 sw=4 et :
