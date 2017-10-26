package Conch::Control::Datacenter;

use strict;
use Log::Any '$log';
use Dancer2::Plugin::Passphrase;
use Conch::Control::User;

use Data::Printer;

use Exporter 'import';
our @EXPORT = qw( get_datacenter_room );

sub get_datacenter_room {
  my ( $schema, $room_id ) = @_;
  my $room = $schema->resultset('DatacenterRoom')->find( { id => $room_id } );
  return $room;
}

1;
