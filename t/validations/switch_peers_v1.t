use v5.20;
use warnings;
use Test::More;
use Test::Conch::Validation 'test_validation';

test_validation(
	'Conch::Validation::SwitchPeers',
	hardware_product => {
		name => 'Test Product',
	},
	device_location => {
		rack_unit_start => 2,
		rack_layouts => [
			{ rack_unit_start => 1 },
			{ rack_unit_start => 2 },
			{ rack_unit_start => 3 },
		],
	},

	cases => [
		{
			description => 'No Data yields no success',
			data        => {},
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

		{
			description => 'Correctly wired peers',
			data        => {
				interfaces => {
					eth0 => {
						peer_port => 'Ethernet2',
						peer_mac  => 'de:ad:be:ef:00:00',
						peer_descr => 'Arista Networks EOS version 1.23.4A running on an Arista Networks DCS-1234-56AB7',
					},
					eth1 => {
						peer_port => 'Ethernet26',
						peer_mac  => 'de:ad:be:ef:00:00',
						peer_descr => 'Arista Networks EOS version 1.23.4A running on an Arista Networks DCS-1234-56AB7',
					},
					eth3 => {
						peer_port => 'Ethernet2',
						peer_mac  => 'co:ff:ee:b0:d1::35',
						peer_descr => 'Arista Networks EOS version 1.23.4A running on an Arista Networks DCS-1234-56AB7',
					},
					eth4 => {
						peer_port => 'Ethernet26',
						peer_mac  => 'co:ff:ee:b0:d1::35',
						peer_descr => 'Arista Networks EOS version 1.23.4A running on an Arista Networks DCS-1234-56AB7',
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
						peer_descr => 'Arista Networks EOS version 1.23.4A running on an Arista Networks DCS-1234-56AB7',
					},
					eth1 => {
						peer_port => 'Ethernet25',
						peer_mac  => 'de:ad:be:ef:00:00',
						peer_descr => 'Arista Networks EOS version 1.23.4A running on an Arista Networks DCS-1234-56AB7',
					},
					eth3 => {
						peer_port => 'Ethernet1',
						peer_mac  => 'co:ff:ee:b0:d1::35',
						peer_descr => 'Arista Networks EOS version 1.23.4A running on an Arista Networks DCS-1234-56AB7',
					},
					eth4 => {
						peer_port => 'Ethernet25',
						peer_mac  => 'co:ff:ee:b0:d1::35',
						peer_descr => 'Arista Networks EOS version 1.23.4A running on an Arista Networks DCS-1234-56AB7',
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
						peer_descr => 'Arista Networks EOS version 1.23.4A running on an Arista Networks DCS-1234-56AB7',
					},
					eth1 => {
						peer_port => 'Ethernet26',
						peer_mac  => 'de:ad:be:ef:00:00',
						peer_descr => 'Arista Networks EOS version 1.23.4A running on an Arista Networks DCS-1234-56AB7',
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
						peer_descr => 'Arista Networks EOS version 1.23.4A running on an Arista Networks DCS-1234-56AB7',
					},
					eth1 => {
						peer_port => 'Ethernet26',
						peer_mac  => 'de:ad:be:ef:00:00',
						peer_descr => 'Arista Networks EOS version 1.23.4A running on an Arista Networks DCS-1234-56AB7',
					},
					eth2 => {
						peer_port => 'Ethernet27',
						peer_mac  => 'de:ad:be:ef:00:00',
						peer_descr => 'Arista Networks EOS version 1.23.4A running on an Arista Networks DCS-1234-56AB7',
					},

					eth3 => {
						peer_port => 'Ethernet2',
						peer_mac  => 'co:ff:ee:b0:d1::35',
						peer_descr => 'Arista Networks EOS version 1.23.4A running on an Arista Networks DCS-1234-56AB7',
					},
					eth4 => {
						peer_port => 'Ethernet26',
						peer_mac  => 'co:ff:ee:b0:d1::35',
						peer_descr => 'Arista Networks EOS version 1.23.4A running on an Arista Networks DCS-1234-56AB7',
					}
				}
			},
			success_num => 6,
			failure_num => 2
		},

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
