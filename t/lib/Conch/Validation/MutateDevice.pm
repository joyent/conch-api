package Conch::Validation::MutateDevice;

use strict;
use warnings;
use warnings FATAL => 'utf8';
use utf8;
use Mojo::Base 'Conch::Validation', -signatures;

sub version { 1 }
sub name { 'mutate_device' }
sub description { 'my description' }
sub category { 'exception' }

sub validate ($self, $data) {
    # this validator is very naughty and tries to write to the database!
    $self->device->asset_tag('King Zøg');
    $self->device->update;

    $self->register_result(
        got => 'hi',
        expected => 'hi',
        component => 'x',
        hint => 'we should have died before getting here',
    );
}

1;
