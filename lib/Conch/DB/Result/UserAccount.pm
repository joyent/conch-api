use utf8;
package Conch::DB::Result::UserAccount;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Conch::DB::Result::UserAccount

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<Conch::DB::InflateColumn::Time>

=item * L<DBIx::Class::Helper::Row::ToJSON>

=back

=cut

__PACKAGE__->load_components("+Conch::DB::InflateColumn::Time", "Helper::Row::ToJSON");

=head1 TABLE: C<user_account>

=cut

__PACKAGE__->table("user_account");

=head1 ACCESSORS

=head2 id

  data_type: 'uuid'
  default_value: gen_random_uuid()
  is_nullable: 0
  size: 16

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 password_hash

  data_type: 'text'
  is_nullable: 0

=head2 created

  data_type: 'timestamp with time zone'
  default_value: current_timestamp
  is_nullable: 0
  original: {default_value => \"now()"}

=head2 last_login

  data_type: 'timestamp with time zone'
  is_nullable: 1

=head2 email

  data_type: 'text'
  is_nullable: 0

=head2 deactivated

  data_type: 'timestamp with time zone'
  is_nullable: 1

=head2 refuse_session_auth

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=head2 force_password_change

  data_type: 'boolean'
  default_value: false
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "uuid",
    default_value => \"gen_random_uuid()",
    is_nullable => 0,
    size => 16,
  },
  "name",
  { data_type => "text", is_nullable => 0 },
  "password_hash",
  { data_type => "text", is_nullable => 0 },
  "created",
  {
    data_type     => "timestamp with time zone",
    default_value => \"current_timestamp",
    is_nullable   => 0,
    original      => { default_value => \"now()" },
  },
  "last_login",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "email",
  { data_type => "text", is_nullable => 0 },
  "deactivated",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "refuse_session_auth",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
  "force_password_change",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<user_account_email_key>

=over 4

=item * L</email>

=back

=cut

__PACKAGE__->add_unique_constraint("user_account_email_key", ["email"]);

=head2 C<user_account_name_key>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("user_account_name_key", ["name"]);

=head1 RELATIONS

=head2 user_relay_connections

Type: has_many

Related object: L<Conch::DB::Result::UserRelayConnection>

=cut

__PACKAGE__->has_many(
  "user_relay_connections",
  "Conch::DB::Result::UserRelayConnection",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_session_tokens

Type: has_many

Related object: L<Conch::DB::Result::UserSessionToken>

=cut

__PACKAGE__->has_many(
  "user_session_tokens",
  "Conch::DB::Result::UserSessionToken",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_settings

Type: has_many

Related object: L<Conch::DB::Result::UserSetting>

=cut

__PACKAGE__->has_many(
  "user_settings",
  "Conch::DB::Result::UserSetting",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_workspace_roles

Type: has_many

Related object: L<Conch::DB::Result::UserWorkspaceRole>

=cut

__PACKAGE__->has_many(
  "user_workspace_roles",
  "Conch::DB::Result::UserWorkspaceRole",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2018-08-03 10:49:18
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:H1YZWElkgjg1bvGLKrka5w

use Crypt::Eksblowfish::Bcrypt qw(bcrypt en_base64);

=head1 METHODS

=head2 new

Overrides original to move 'password' to 'password_hash'.

=cut

sub new {
    my ($self, $args) = @_;

    # extract non-column data to store in the right place
    $args->{password_hash} = _hash_password(delete $args->{password})
        if exists $args->{password};

    $self = $self->next::method($args);

    return $self;
}

=head2 update

Overrides original to move 'password' to 'password_hash'.

=cut

sub update {
    my ($self, $args) = @_;

    # extract non-column data to store in the right place
    $args->{password_hash} = _hash_password(delete $args->{password})
        if exists $args->{password};

    $self = $self->next::method($args);
}

=head2 validate_password

Check whether the given password text has a hash matching the stored password hash.

=cut

sub validate_password {
    my ($self, $p) = @_;

    # handle legacy Dancer passwords (TODO: remove all remaining CRYPT constructs from
    # passwords in the database using a migration script.)
    (my $password_hash = $self->password_hash) =~ s/^{CRYPT}//;

    return Mojo::Util::secure_compare(
        $password_hash,
        bcrypt($p, $password_hash),
    );
}

use constant _BCRYPT_COST => 4; # dancer2 legacy

sub _hash_password {
    my $p = shift;
    my $cost = sprintf( '%02d', _BCRYPT_COST || 6 );
    my $settings = join( '$', '$2a', $cost, _bcrypt_salt() );
    return bcrypt( $p, $settings );
}

sub _bcrypt_salt {
    my $num = 999999;
    my $cr = crypt( rand($num), rand($num) ) . crypt( rand($num), rand($num) );
    en_base64( substr( $cr, 4, 16 ) );
}

1;
__END__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at http://mozilla.org/MPL/2.0/.

=cut
# vim: set ts=4 sts=4 sw=4 et :
