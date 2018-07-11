use Test::More;
use Test::Conch::Validation;

test_validation(
	'Conch::Validation::SwitchPeers',
	hardware_product => {
		name => 'Test Product',
	},
	device_location => {
		rack_unit       => 2,
		datacenter_rack => { slots => [ 1, 2, 3 ] }
	},

	cases => [
		{
			description => 'No Data',
			data        => {},
			dies        => 1
		},
		{
			description =>
				'Single failure with no eth interfaces (num of switch ports)',
			data        => { interfaces => {} },
			failure_num => 1
		},
		{
			description => 'Correctly wired peers',
			data        => {
				interfaces => {
					eth0 => {
						peer_port => '1/2',
						peer_mac  => 'de:ad:be:ef:00:00',
					},
					eth1 => {
						peer_port => '1/21',
						peer_mac  => 'de:ad:be:ef:00:00',
					},
					eth3 => {
						peer_port => '1/2',
						peer_mac  => 'co:ff:ee:b0:d1::35',
					},
					eth4 => {
						peer_port => '1/21',
						peer_mac  => 'co:ff:ee:b0:d1::35',
					}
				}
			},
			success_num => 7,
			failure_num => 0
		},
		{
			description => 'Only mis-wired peer ports',
			data        => {
				interfaces => {
					eth0 => {
						peer_port => '1/1',
						peer_mac  => 'de:ad:be:ef:00:00',
					},
					eth1 => {
						peer_port => '1/20',
						peer_mac  => 'de:ad:be:ef:00:00',
					},
					eth3 => {
						peer_port => '1/1',
						peer_mac  => 'co:ff:ee:b0:d1::35',
					},
					eth4 => {
						peer_port => '1/20',
						peer_mac  => 'co:ff:ee:b0:d1::35',
					}
				}
			},
			success_num => 3,
			failure_num => 4
		},
		{
			description => 'Incorrect number of peer switches',
			data        => {
				interfaces => {
					eth0 => {
						peer_port => '1/2',
						peer_mac  => 'de:ad:be:ef:00:00',
					},
					eth1 => {
						peer_port => '1/21',
						peer_mac  => 'de:ad:be:ef:00:00',
					},
				}
			},
			success_num => 3,
			failure_num => 1
		},
		{
			description => 'Incorrect number of ports per switch',
			data        => {
				interfaces => {
					eth0 => {
						peer_port => '1/2',
						peer_mac  => 'de:ad:be:ef:00:00',
					},
					eth1 => {
						peer_port => '1/21',
						peer_mac  => 'de:ad:be:ef:00:00',
					},
					eth2 => {
						peer_port => '1/22',
						peer_mac  => 'de:ad:be:ef:00:00',
					},

					eth3 => {
						peer_port => '1/2',
						peer_mac  => 'co:ff:ee:b0:d1::35',
					},
					eth4 => {
						peer_port => '1/21',
						peer_mac  => 'co:ff:ee:b0:d1::35',
					}
				}
			},
			success_num => 6,
			failure_num => 2
		},
	]
);

test_validation(
	'Conch::Validation::SwitchPeers',
	hardware_product => {
		name => 'Test Product',
	},
	device_location => {
		rack_unit       => 5,
		datacenter_rack => { slots => [ 1, 2, 3 ] }
	},

	cases => [
		{
			description => 'Dies if rack unit not in slots',
			data        => {
				interfaces => {
					eth0 => {
						peer_port => '1/2',
						peer_mac  => 'de:ad:be:ef:00:00',
					},
					eth1 => {
						peer_port => '1/21',
						peer_mac  => 'de:ad:be:ef:00:00',
					},
					eth3 => {
						peer_port => '1/2',
						peer_mac  => 'co:ff:ee:b0:d1::35',
					},
					eth4 => {
						peer_port => '1/21',
						peer_mac  => 'co:ff:ee:b0:d1::35',
					}
				}
			},
			dies => 1
		},
	]
);

my $descr = "Arista Networks EOS version 1.23.4A running on an Arista Networks DCS-1234-56AB7";

test_validation(
	'Conch::Validation::SwitchPeers',
	hardware_product => {
		name => 'Test Product',
	},
	device_location => {
		rack_unit       => 2,
		datacenter_rack => { slots => [ 1, 2, 3 ] }
	},

	cases => [
		{
			description => 'No Data',
			data        => {},
			dies        => 1
		},
		{
			description =>
				'Single failure with no eth interfaces (num of switch ports)',
			data        => { interfaces => {} },
			failure_num => 1
		},
		{
			description => 'Correctly wired peers',
			data        => {
				interfaces => {
					eth0 => {
						peer_port => 'Ethernet2',
						peer_mac  => 'de:ad:be:ef:00:00',
						peer_descr => $descr,
					},
					eth1 => {
						peer_port => 'Ethernet26',
						peer_mac  => 'de:ad:be:ef:00:00',
						peer_descr => $descr,
					},
					eth3 => {
						peer_port => 'Ethernet2',
						peer_mac  => 'co:ff:ee:b0:d1::35',
						peer_descr => $descr,
					},
					eth4 => {
						peer_port => 'Ethernet26',
						peer_mac  => 'co:ff:ee:b0:d1::35',
						peer_descr => $descr,
					}
				}
			},
			success_num => 7,
			failure_num => 0
		},
		{
			description => 'Only mis-wired peer ports',
			data        => {
				interfaces => {
					eth0 => {
						peer_port => 'Ethernet1',
						peer_mac  => 'de:ad:be:ef:00:00',
						peer_descr => $descr,
					},
					eth1 => {
						peer_port => 'Ethernet25',
						peer_mac  => 'de:ad:be:ef:00:00',
						peer_descr => $descr,
					},
					eth3 => {
						peer_port => 'Ethernet1',
						peer_mac  => 'co:ff:ee:b0:d1::35',
						peer_descr => $descr,
					},
					eth4 => {
						peer_port => 'Ethernet25',
						peer_mac  => 'co:ff:ee:b0:d1::35',
						peer_descr => $descr,
					}
				}
			},
			success_num => 3,
			failure_num => 4
		},
		{
			description => 'Incorrect number of peer switches',
			data        => {
				interfaces => {
					eth0 => {
						peer_port => 'Ethernet2',
						peer_mac  => 'de:ad:be:ef:00:00',
						peer_descr => $descr,
					},
					eth1 => {
						peer_port => 'Ethernet26',
						peer_mac  => 'de:ad:be:ef:00:00',
						peer_descr => $descr,
					},
				}
			},
			success_num => 3,
			failure_num => 1
		},
		{
			description => 'Incorrect number of ports per switch',
			data        => {
				interfaces => {
					eth0 => {
						peer_port => 'Ethernet2',
						peer_mac  => 'de:ad:be:ef:00:00',
						peer_descr => $descr,
					},
					eth1 => {
						peer_port => 'Ethernet26',
						peer_mac  => 'de:ad:be:ef:00:00',
						peer_descr => $descr,
					},
					eth2 => {
						peer_port => 'Ethernet27',
						peer_mac  => 'de:ad:be:ef:00:00',
						peer_descr => $descr,
					},

					eth3 => {
						peer_port => 'Ethernet2',
						peer_mac  => 'co:ff:ee:b0:d1::35',
						peer_descr => $descr,
					},
					eth4 => {
						peer_port => 'Ethernet26',
						peer_mac  => 'co:ff:ee:b0:d1::35',
						peer_descr => $descr,
					}
				}
			},
			success_num => 6,
			failure_num => 2
		},
	]
);

test_validation(
	'Conch::Validation::SwitchPeers',
	hardware_product => {
		name => 'Test Product',
	},
	device_location => {
		rack_unit       => 2,
		datacenter_rack => { slots => [ 1, 2, 3 ] }
	},

	cases => [
		{
			description => 'Correctly wired peers',
			data        => {
				interfaces => {
					eth0 => {
						peer_port => 'Ethernet2',
						peer_mac  => 'de:ad:be:ef:00:00',
						peer_vendor => 'Arista',
					},
					eth1 => {
						peer_port => 'Ethernet26',
						peer_mac  => 'de:ad:be:ef:00:00',
						peer_vendor => 'Arista',
					},
					eth3 => {
						peer_port => 'Ethernet2',
						peer_mac  => 'co:ff:ee:b0:d1::35',
						peer_vendor => 'Arista',
					},
					eth4 => {
						peer_port => 'Ethernet26',
						peer_mac  => 'co:ff:ee:b0:d1::35',
						peer_vendor => 'Arista',
					}
				}
			},
			success_num => 7,
			failure_num => 0
		},
		{
			description => 'Only mis-wired peer ports',
			data        => {
				interfaces => {
					eth0 => {
						peer_port => 'Ethernet1',
						peer_mac  => 'de:ad:be:ef:00:00',
						peer_vendor => 'Arista',
					},
					eth1 => {
						peer_port => 'Ethernet25',
						peer_mac  => 'de:ad:be:ef:00:00',
						peer_vendor => 'Arista',
					},
					eth3 => {
						peer_port => 'Ethernet1',
						peer_mac  => 'co:ff:ee:b0:d1::35',
						peer_vendor => 'Arista',
					},
					eth4 => {
						peer_port => 'Ethernet25',
						peer_mac  => 'co:ff:ee:b0:d1::35',
						peer_vendor => 'Arista',
					}
				}
			},
			success_num => 3,
			failure_num => 4
		},
		{
			description => 'Incorrect number of peer switches',
			data        => {
				interfaces => {
					eth0 => {
						peer_port => 'Ethernet2',
						peer_mac  => 'de:ad:be:ef:00:00',
						peer_vendor => 'Arista',
					},
					eth1 => {
						peer_port => 'Ethernet26',
						peer_mac  => 'de:ad:be:ef:00:00',
						peer_vendor => 'Arista',
					},
				}
			},
			success_num => 3,
			failure_num => 1
		},
		{
			description => 'Incorrect number of ports per switch',
			data        => {
				interfaces => {
					eth0 => {
						peer_port => 'Ethernet2',
						peer_mac  => 'de:ad:be:ef:00:00',
						peer_vendor => 'Arista',
					},
					eth1 => {
						peer_port => 'Ethernet26',
						peer_mac  => 'de:ad:be:ef:00:00',
						peer_vendor => 'Arista',
					},
					eth2 => {
						peer_port => 'Ethernet27',
						peer_mac  => 'de:ad:be:ef:00:00',
						peer_vendor => 'Arista',
					},

					eth3 => {
						peer_port => 'Ethernet2',
						peer_mac  => 'co:ff:ee:b0:d1::35',
						peer_vendor => 'Arista',
					},
					eth4 => {
						peer_port => 'Ethernet26',
						peer_mac  => 'co:ff:ee:b0:d1::35',
						peer_vendor => 'Arista',
					}
				}
			},
			success_num => 6,
			failure_num => 2
		},
	]
);

done_testing();
