package Conch::Validation::MultipleResults;

use Mojo::Base 'Conch::Validation', -signatures;

sub version { 1 }
sub name { 'multiple_results' }
sub description { 'my description' }
sub category { 'multi' }

sub validate ($self, $data) {

    $self->register_result(
        got => 'hi',
        expected => 'hi',
        component_id => 'x',
        hint => 'this is ignored',
    );
    $self->register_result(
        got => 'yay',
        expected => 'nay',
        name => 'new name',
        message => 'new message',
        category => 'new category',
        component_id => 'y',
        hint => 'stfu',
    );
}

1;
