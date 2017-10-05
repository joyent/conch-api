package Conch::Control::Datacenter;

use strict;
use Log::Any '$log';
use Dancer2::Plugin::Passphrase;
use Conch::Control::User;

use Data::Printer;

use Exporter 'import';
our @EXPORT = qw( get_datacenter_room set_datacenter_room_access );

sub get_datacenter_room {
  my ( $schema, $room_id ) = @_;
  my $room = $schema->resultset('DatacenterRoom')->find( { id => $room_id } );
  return $room;
}

# Replace and sets (idempotent) datacenter room access for a hash of user names
# and list of datacenter rooms.
#
# Empty lists associated with a user name don't do anything, because elements
# of a hash must be scalars. This could probably be fixed by replacing the hash
# with a Moose object with an undef-able attribute for the datacenter list
#
# To delete all datacenter room access, pass a list with a single value that is
# not a valid room identifier.
sub set_datacenter_room_access {
  my ( $schema, $user, $room_access ) = @_;

  foreach my $user_name ( keys %{$room_access} ) {
    my @datacenter_room_keys = $room_access->{$user_name};
    my $user = lookup_user_by_name( $schema, $user_name );
    $user or die $log->error("user name $user_name does not exist");

    #XXX How will refer to the datacenter room in the event? Vendor name? AZ?
    # Stubbed this with 'az' for now
    my @datacenter_rooms = $schema->resultset('DatacenterRoom')
      ->search( { az => { -in => @datacenter_room_keys } } );

    scalar @datacenter_rooms
      or $log->warning("No valid datacenter rooms found for user '$user_name'");

   # XXX BUG: https://app.liquidplanner.com/space/174715/projects/show/39854773P
   # XXX Only works for updating a single row?
   # XXX This isn't a list; it's being truncated upstream.
   # XXX Orig:
   #$user->set_datacenter_rooms(@datacenter_rooms || [])
   # XXX Still busted:
    foreach my $room (@datacenter_rooms) {
      $user->set_datacenter_rooms( $room || [] );
    }
  }
}

1;
