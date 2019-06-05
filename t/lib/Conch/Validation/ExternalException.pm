package Conch::Validation::ExternalException;

use Mojo::Base 'Conch::Validation', -signatures;
use JSON::PP 'decode_json';

sub version { 1 }
sub name { 'external exception' }
sub description { 'my description' }
sub category { 'exception' }

sub validate ($self, $data) {
    my $got = decode_json('{"foo');
    $self->register_result(
        got => $got,
        expected => 'hi',
        component => 'x',
        hint => 'we should have died before getting here',
    );
}

1;
