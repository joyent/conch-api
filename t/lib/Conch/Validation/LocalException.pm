package Conch::Validation::LocalException;

use Mojo::Base 'Conch::Validation', -signatures;

sub version { 1 }
sub name { 'local_exception' }
sub description { 'my description' }
sub category { 'exception' }

sub validate ($self, $data) {
    die 'I did something dumb';
}

1;
