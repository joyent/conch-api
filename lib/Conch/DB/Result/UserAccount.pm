use utf8;
package Conch::DB::Result::UserAccount;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Conch::DB::Result::UserAccount

=cut

use strict;
use warnings;


=head1 BASE CLASS: L<Conch::DB::Result>

=cut

use base 'Conch::DB::Result';

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

=head2 password

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

=head2 is_admin

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
  "password",
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
  "is_admin",
  { data_type => "boolean", default_value => \"false", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

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


# Created by DBIx::Class::Schema::Loader v0.07049
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:oCbg42AWlr5N3Qt7+pLmKA

use DBIx::Class::PassphraseColumn 0.04 ();
__PACKAGE__->load_components('PassphraseColumn');

__PACKAGE__->add_columns(
    '+password' => {
        is_serializable  => 0,
        passphrase       => 'crypt',    # encoding used: 'rfc2307' or 'crypt'
        passphrase_class => 'BlowfishCrypt',
        passphrase_args  => {   # args passed to Authen::Passphrase::BlowfishCrypt->new
            cost => (!$ENV{MOJO_MODE} && $ENV{CONCH_BLOWFISH_COST}) || 16,
            salt_random => 1,
        },
        passphrase_check_method => 'check_password',
    },
    '+deactivated' => { is_serializable => 0 },
);

use experimental 'signatures';

=head1 METHODS

=head2 check_password

Checks the provided password against the value in the database, returning true/false.
Because hard cryptography is used, this is *not* a fast call!

=head2 TO_JSON

Include information about the user's workspaces, if available.

=cut

sub TO_JSON ($self) {
    my $data = $self->next::method(@_);

    # Mojo::JSON renders \0, \1 as json booleans
    $data->{$_} = \(0+$data->{$_}) for qw(refuse_session_auth force_password_change is_admin);

    # add workspace data, if it has been prefetched
    if (my $cached_uwrs = $self->related_resultset('user_workspace_roles')->get_cache) {
        my %seen_workspaces;
        $data->{workspaces} = [
            # we process the direct uwr+workspace entries first so we do not produce redundant rows
            (map {
                my $workspace = $_->workspace;
                ++$seen_workspaces{$workspace->id};
                +{
                    $workspace->TO_JSON->%*,
                    role => $_->role,
                },
            } $cached_uwrs->@*),

            (map {
                map {
                    # $_ is a workspace where the user inherits a role
                    $seen_workspaces{$_->id} ? () : do {
                        ++$seen_workspaces{$_->id};
                        $_->user_id_for_role($self->id);
                        $_->TO_JSON
                    }
                } $self->result_source->schema->resultset('workspace')
                    ->workspaces_beneath($_->workspace_id)
            } $cached_uwrs->@*),
        ];
    }

    return $data;
}

1;
__END__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<http://mozilla.org/MPL/2.0/>.

=cut
# vim: set ts=4 sts=4 sw=4 et :
