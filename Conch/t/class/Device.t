use Mojo::Base -strict;
use Test::More;

use Data::Printer;

use_ok("Conch::Class::Device");
new_ok('Conch::Class::Device');
new_ok(
	"Conch::Class::Device", [
		id                   => 'id',
		asset_tag            => 'asset_tag',
		boot_phase           => 'boot_phase',
		created              => 'created',
		hardware_product     => 'hardware_product',
		health               => 'health',
		graduated            => 'graduated',
		last_seen            => 'last_seen',
		latest_triton_reboot => 'latest_triton_reboot',
		role                 => 'role',
		state                => 'state',
		system_uuid          => 'system_uuid',
		triton_uuid          => 'triton_uuid',
		updated              => 'updated',
		uptime_since         => 'uptime_since',
		validated            => 'validated'
	]
);

fail("Test more than constructors");

done_testing();

