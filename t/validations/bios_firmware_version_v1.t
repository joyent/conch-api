use v5.20;
use warnings;

use Mojo::Log;
use Conch::Models;
use Conch::Validations;
use Test2::Conch::Validations;

my $t = Test2::Conch::Validations->new();
Conch::Validations->load( Mojo::Log->new() );

my $v = Conch::Validation::BiosFirmwareVersion->new();

my $d = Conch::Model::Device->create(
	'test_device', 
	Conch::Model::HardwareProduct->lookup_by_name("65-ssds-2-cpu")->id,
);

Conch::Model::DeviceLocation->new()->assign(
	$d->id,
	Conch::Model::DatacenterRack->from_name('Test Rack')->id,
	1
);

$t->fail($v, $d, { 
	bios_version => '1.2',
});

$t->done();
