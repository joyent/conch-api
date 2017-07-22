package Conch::Control::Datacenter;

use strict;
use Log::Report;
use Dancer2::Plugin::Passphrase;
use Conch::Control::User;

use Data::Dumper;

use Exporter 'import';
our @EXPORT = qw( set_datacenter_room_access );

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
  my ($schema, $room_access) = @_;

  foreach my $user_name (keys %{$room_access}) {
    my @datacenter_room_keys = $room_access->{$user_name};
    my $user = lookup_user_by_name($schema, $user_name);
    $user or error "user name $user_name does not exist";

    #XXX How will refer to the datacenter room in the event? Vendor name? AZ?
    # Stubbed this with 'az' for now
    my @datacenter_rooms = $schema->resultset('DatacenterRoom')->search(
      { az => { -in => @datacenter_room_keys } }
    );

    scalar @datacenter_rooms 
      or warning "No valid datacenter rooms found for user '$user_name'";

    $user->set_datacenter_rooms(@datacenter_rooms || [])
  }
};


1;
