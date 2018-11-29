package Conch::Validation::WrongVersion;
use Mojo::Base 'Conch::Validation';
sub version { 2 }
sub name { 'wrong version' }
sub description { 'validation with wrong version' }
1;
