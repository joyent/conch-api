use utf8;
package Conch::DB;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces(
    default_resultset_class => "+Conch::DB::ResultSet",
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2018-08-24 15:58:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:QkdW/OL4Wq8k9yZp3hGDMg

# register sources as <table_name>, rather than <TableName>, for nicer grepping...
# that is, you should do $schema->resultset('user_account'), not ->resultset('UserAccount').
foreach my $old_source_name (__PACKAGE__->sources) {
    my $source = __PACKAGE__->source($old_source_name);
    __PACKAGE__->unregister_source($old_source_name);
    __PACKAGE__->register_source($source->from, $source);
}

1;
__END__

=pod

=head1 NAME

Conch::DB

=head1 DESCRIPTION

Base schema class for the Conch application. See L<DBIx::Class::Schema>.

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<http://mozilla.org/MPL/2.0/>.

=cut
# vim: set ts=4 sts=4 sw=4 et :
