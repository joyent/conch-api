package Conch::Validation::WrongDescription;
use Mojo::Base 'Conch::Validation';
sub version { 1 }
sub name { 'wrong description' }
sub description { 'this does not match \'description\' in the database' }
1;
