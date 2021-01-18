package Conch::Controller::User;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Conch::UUID 'is_uuid';
use Email::Valid;
use List::Util 'pairmap';
use Authen::Passphrase::RejectAll;
use feature 'fc';

=pod

=head1 NAME

Conch::Controller::User

=head1 METHODS

=head2 find_user

Chainable action that uses the C<target_user_id_or_email> value provided in the stash (usually
via the request URL) to look up a user, and stashes the result in C<target_user>.

=cut

sub find_user ($c) {
    my $identifier = $c->stash('target_user_id_or_email');
    my $user_rs = $c->db_user_accounts;

    $c->log->debug('looking up user '.$identifier);
    my $user = is_uuid($identifier) ? $user_rs->find($identifier)
        : Email::Valid->address($identifier) ? $user_rs->find_by_email($identifier)
        : return $c->status(400, { error => 'invalid identifier format for '.$identifier });

    if (not $user) {
        $c->log->debug('Could not find user '.$identifier);
        return $c->status(404);
    }

    if ($user->deactivated) {
        $c->stash('response_schema', 'UserError') if $c->is_system_admin;
        return $c->status(410, {
            error => 'user is deactivated',
            $c->is_system_admin ? ( user => { map +($_ => $user->$_), qw(id email name created deactivated) } ) : (),
        });
    }

    $c->stash('target_user', $user);
    return 1;
}

=head2 revoke_user_tokens

Revoke a specified user's tokens and prevents future token authentication,
forcing the user to /login again. By default B<all> of a user's tokens are deleted,
but this can be adjusted with query parameters:

 * C<?login_only=1> login tokens are removed; api tokens are left alone
 * C<?api_only=1>   login tokens are left alone; api tokens are removed

If login tokens are affected, C<refuse_session_auth> is also set for the user, which forces the
user to change his password as soon as a login token is used again (but use of any existing api
tokens is allowed).

System admin only (unless reached via /user/me).

Sends an email to the affected user, unless C<?send_mail=0> is included in the query (or
revoking for oneself).

=cut

sub revoke_user_tokens ($c) {
    my $params = $c->stash('query_params');

    my $login_only = $params->{login_only};
    my $api_only = $params->{api_only};

    my $user = $c->stash('target_user');
    $c->log->debug('revoking '
        .($login_only ? 'login' : $api_only ? 'api' : 'all')
        .' tokens for user '.$user->name.', forcing them to /login again');

    my $send_mail = $user->id ne $c->stash('user_id') && $params->{send_mail};

    my $rs = $user->user_session_tokens->unexpired;
    $rs = $rs->login_only if $login_only;
    $rs = $rs->api_only if $api_only;
    my @token_names = $send_mail ? $rs->order_by('name')->get_column('name')->all : ();
    $rs->expire;

    if (@token_names and $send_mail) {
        my @removed_login_tokens = grep /^login_jwt_/, @token_names;
        @token_names = (
            (grep !/^login_jwt_/, @token_names),
            @removed_login_tokens
                ? scalar(@removed_login_tokens).' login token'.(@removed_login_tokens > 1 ? 's' : '')
                : (),
        );

        $c->send_mail(
            template_file => 'revoked_user_tokens',
            From => 'noreply',
            Subject => 'Your Conch tokens have been revoked',
            token_names => \@token_names,
        );
    }

    $user->update({ refuse_session_auth => 1 }) if $login_only;

    $c->status(204);
}

=head2 set_settings

Override the settings for a user with the provided payload

=cut

sub set_settings ($c) {
    my $input = $c->stash('request_data');

    my $rs = $c->stash('target_user')->related_resultset('user_settings');

    $c->schema->txn_do(sub {
        # deactivate *all* settings first
        $rs->active->deactivate;

        # store new settings
        $rs->populate([ pairmap { +{ name => $a, value => $b } } $input->%* ]);
    });

    $c->status(204);
}

=head2 set_setting

Set the value of a single setting for the target user.

FIXME: the key name is repeated in the URL and the payload :(

=cut

sub set_setting ($c) {
    my $input = $c->stash('request_data');

    my $key = $c->stash('key');
    return $c->status(400, { error => 'Setting key in request payload must match name in the URL (\''.$key.'\')' })
        if not exists $input->{$key};

    my $value = $input->{$key};

    my $settings_rs = $c->db_user_settings->search({ user_id => $c->stash('target_user')->id });

    # return early if the setting exists and is not being altered
    my $existing_value = $settings_rs->active->search({ name => $key })->get_column('value')->single;
    return $c->status(204) if $existing_value and $existing_value eq $value;

    $c->schema->txn_do(sub {
        $settings_rs->search({ name => $key })->active->deactivate;
        $settings_rs->create({ name => $key, value => $value });
    });

    return $c->status(204);
}

=head2 get_settings

Get the key/values of every setting for a user.

Response uses the UserSettings json schema.

=cut

sub get_settings ($c) {
    # turn user_setting db rows into name => value entries,
    # newer entries overwriting older ones
    my %output = map
        +($_->name => $_->value),
        $c->stash('target_user')->related_resultset('user_settings')->active->order_by('created');

    $c->status(200, \%output);
}

=head2 get_setting

Get the individual key/value pair for a setting for the target user.

Response uses the UserSetting json schema.

=cut

sub get_setting ($c) {
    my $key = $c->stash('key');
    my $setting = $c->stash('target_user')
        ->search_related('user_settings', { name => $key })
        ->active
        ->order_by({ -desc => 'created' })
        ->one_row;

    if (not $setting) {
        $c->log->debug('Could not find user setting '.$key.' for user '.$c->stash('target_user')->email);
        return $c->status(404);
    }

    $c->status(200, { $key => $setting->value });
}

=head2 delete_setting

Delete a single setting for a user, provided it was set previously.

=cut

sub delete_setting ($c) {
    my $count = $c->stash('target_user')
        ->search_related('user_settings', { name => $c->stash('key') })
        ->active
        ->deactivate;

    return $c->status($count ? 204 : 404);
}

=head2 change_own_password

Stores a new password for the current user.

Optionally takes a query parameter C<clear_tokens>, to also revoke session tokens for the user,
forcing the user to log in again. Possible options are:

  * none
  * login_only (default) - clear login tokens only
  * all - clear all tokens (login and api - affects all APIs and tools)

When login tokens are cleared, the user is also logged out.

=cut

sub change_own_password ($c) {
    my $params = $c->stash('query_params');
    my $input = $c->stash('request_data');

    my $clear_tokens = $params->{clear_tokens};

    my $user = $c->stash('user');
    $user->update({
        password => $input->{password},
        refuse_session_auth => 0,
        force_password_change => 0,
    });

    $c->log->info('updated password for user '.$user->name.' ('.$user->email.') at their request'
        .($clear_tokens eq 'none' ? ''
            : '; clearing '.($clear_tokens eq 'login_only'?'login':$clear_tokens).' tokens'));

    return $c->status(204) if $clear_tokens eq 'none';

    my $rs = $user->user_session_tokens;
    $rs = $rs->login_only if $clear_tokens ne 'all';
    $rs->expire;

    # processing continues with Conch::Controller::Login::logout
    return 1;
}

=head2 reset_user_password

Generates a new random password for a user. System admin only.

Optionally takes a query parameter C<send_mail> (defaulting to true), to send an
email to the user with the new password.

Optionally takes a query parameter C<clear_tokens>, to also revoke session tokens for the user,
forcing the user to log in again. Possible options are:

  * none
  * login_only (default)
  * all - clear all tokens (login and api - affects all APIs and tools)

If all tokens are revoked, the user must also change their password after logging in, as they
will not be able to log in with it again.

=cut

sub reset_user_password ($c) {
    my $params = $c->stash('query_params');
    my $clear_tokens = $params->{clear_tokens};

    my $user = $c->stash('target_user');
    my %update = (
        password => $c->random_string(),
    );

    if ($clear_tokens ne 'none') {
        my $rs = $user->user_session_tokens;
        $rs = $rs->login_only if $clear_tokens ne 'all';
        my $count = $rs->delete;

        $c->log->warn('user '.$c->stash('user')->name.' deleted '.($count+0)
            .($clear_tokens eq 'all' ? ' all' : ' (login only)')
            .' user session tokens for user '.$user->name);

        %update = (
            %update,

            # subsequent attempts to authenticate with the browser session will return
            # 401 unauthorized, except for the /user/me/password endpoint
            refuse_session_auth => 1,

            # the next /login access will result in another password reset,
            # a reminder to the user to change their password,
            # and the session expiration will be reduced to 10 min
            force_password_change => 1,
        );
    }

    $c->log->warn('user '.$c->stash('user')->name.' resetting password for user '.$user->name);
    $user->update({ %update });

    $c->send_mail(
        template_file => 'changed_user_password',
        From => 'noreply',
        Subject => 'Your Conch password has changed',
        password => $update{password},
    ) if $params->{send_mail};

    return $c->status(204);
}

=head2 get

Gets information about a user. System admin only (unless reached via /user/me).
Response uses the UserDetailed json schema.

=cut

sub get ($c) {
    my ($user) = $c->db_user_accounts
        ->search({ 'user_account.id' => $c->stash('target_user')->id })
        ->prefetch({
                user_organization_roles => { organization => {
                        organization_build_roles => 'build',
                    } },
                user_build_roles => 'build',
            })
        # no need to filter out deactivated rows here, as the *_roles rows will be removed
        ->order_by([ map $_.'.name', qw(organization build) ])
        ->all;

    return $c->status(200, $user);
}

=head2 update

Updates user attributes. System admin only, unless the target user is the authenticated user.
Sends an email to the affected user, unless C<?send_mail=0> is included in the query.

The response uses the UserError json schema for some error conditions; on success, redirects to
C<GET /user/:id>.

=cut

sub update ($c) {
    my $params = $c->stash('query_params');
    my $input = $c->stash('request_data');

    return $c->status(400, { error => 'user email "'.$input->{email}.'" is not a valid RFC822 address' })
        if exists $input->{email} and not Email::Valid->address($input->{email});

    my $is_system_admin = $c->is_system_admin;

    if ($is_system_admin and not $INC{'Test/More.pm'} and my $conch_ui_version = $c->req->headers->header('X-Conch-UI')) {
      my ($major, $minor, $tiny) = $conch_ui_version =~ /^v(\d+)\.(\d+)(?:\.(\d+))?/;
      return $c->status(403, { error => 'this api is blocked until https://github.com/joyent/conch-ui/issues/303 is fixed' })
        if $major == 4 and $minor == 1 and ($tiny//0) == 0;
    }

    my $user = $c->stash('target_user');
    my %orig_columns = $user->get_columns;
    $user->set_columns($input);
    my %dirty_columns = $user->get_dirty_columns;

    return $c->status(204) if not %dirty_columns;

    return $c->status(403) if $dirty_columns{is_admin} and not $is_system_admin;

    if (my $dupe_user =
            (exists $dirty_columns{email} && (fc $input->{email} ne fc $orig_columns{email})
                && $c->db_user_accounts->active->find_by_email($input->{email}))
            || (exists $dirty_columns{name}
                && $c->db_user_accounts->active->search({ name => $input->{name} })->single) ) {
        $c->stash('response_schema', 'UserError') if $is_system_admin;
        return $c->status(409, {
            error => 'duplicate user found',
            $is_system_admin ? ( user => { map +($_ => $dupe_user->$_), qw(id email name created deactivated) } ) : (),
        });
    }

    if ($params->{send_mail}) {
        %orig_columns = %orig_columns{keys %dirty_columns};

        if (exists $dirty_columns{is_admin}) {
            $_ = $_ ? 'true' : 'false' foreach $orig_columns{is_admin}, $dirty_columns{is_admin};
        }

        $c->send_mail(
            template_file => 'updated_user_account',
            From => 'noreply',
            Subject => 'Your Conch account has been updated',
            orig_data => \%orig_columns,
            new_data => \%dirty_columns,
        );
    }

    $c->log->debug('updating user '.$user->email.': '.$c->req->text);
    $user->update;

    $c->status(204, '/user/'.$user->id);
}

=head2 get_all

List all active users. System admin only.
Response uses the Users json schema.

=cut

sub get_all ($c) {
    my $user_rs = $c->db_user_accounts
        ->active
        ->order_by('name');

    return $c->status(200, [ $user_rs->all ]);
}

=head2 create

Creates a user. System admin only.

Optionally takes a query parameter C<send_mail> (defaulting to true), to send an
email to the user with the new password.

Response uses the NewUser json schema (or UserError for some error conditions).

=cut

sub create ($c) {
    my $params = $c->stash('query_params');
    my $input = $c->stash('request_data');

    return $c->status(400, { error => 'user email "'.$input->{email}.'" is not a valid RFC822 address' })
        if not Email::Valid->address($input->{email});

    # this would cause horrible clashes with our /user routes!
    return $c->status(400, { error => 'user name "me" is prohibited' }) if $input->{name} eq 'me';

    if (my $dupe_user = $c->db_user_accounts->active->search({ name => $input->{name} })->single
            || $c->db_user_accounts->active->find_by_email($input->{email})) {
        $c->stash('response_schema', 'UserError');
        return $c->status(409, {
            error => 'duplicate user found',
            user => { map +($_ => $dupe_user->$_), qw(id email name created deactivated) },
        });
    }

    $input->{password} //= $c->random_string;
    $input->{is_admin} = $input->{is_admin} ? 1 : 0;

    # password will be hashed in Conch::DB::Result::UserAccount constructor
    my $user = $c->db_user_accounts->create({ $input->%*, force_password_change => 1 });
    $c->log->info('created user: '.$user->name.', email: '.$user->email.', id: '.$user->id);

    if ($params->{send_mail}) {
        $c->stash('target_user', $user);
        $c->send_mail(
            template_file => 'new_user_account',
            From => 'noreply',
            Subject => 'Welcome to Conch!',
            password => $input->{password},
        );
    }

    $c->res_location('/user/'.$user->id);
    return $c->status(201, { map +($_ => $user->$_), qw(id email name) });
}

=head2 deactivate

Deactivates a user. System admin only.

Optionally takes a query parameter C<clear_tokens> (defaulting to true), to also revoke all
session tokens for the user, which would force all tools to log in again should the account be
reactivated (for which there is no api endpoint at present).

All memberships in organizations and builds are removed and are not recoverable.

Response uses the UserError json schema on some error conditions.

=cut

sub deactivate ($c) {
    my $params = $c->stash('query_params');
    my $user = $c->stash('target_user');

    # do not allow removing user if he is the only admin of an organization or build
    foreach my $type (qw(organization build)) {
        my $rs_name = 'db_'.$type.'s';
        my $admins_rs = $c->$rs_name->correlate('user_'.$type.'_roles')->search({ role => 'admin' });
        my $rs = $c->$rs_name->search(
            { user_id => $user->id, role => 'admin' },
            {
                '+select' => [{ '' => $admins_rs->count_rs->as_query, -as => 'admin_count' }],
                join => 'user_'.$type.'_roles',
            },
        )
        ->as_subselect_rs
        ->search({ admin_count => 1 })
        ->order_by($type.'.name');

        if (my $thing = $rs->rows(1)->one_row) {
            $c->stash('response_schema', 'UserError');
            return $c->status(409, {
                error => 'user is the only admin of the "'.$thing->name.'" '.$type.' ('.$thing->id.')',
                user => { map +($_ => $user->$_), qw(id email name created deactivated) },
            });
        }
    }

    my $organizations = join(', ', map $_->{organization}{name}.' ('.$_->{role}.')',
        $user->search_related('user_organization_roles', undef, { join => 'organization' })
            ->columns([ qw(organization.name role) ])->hri->all);
    my $builds = join(', ', map $_->{build}{name}.' ('.$_->{role}.')',
        $user->search_related('user_build_roles', undef, { join => 'build' })
            ->columns([ qw(build.name role) ])->hri->all);

    $c->log->warn('user '.$c->stash('user')->name.' deactivating user '.$user->name
        .($organizations ? ', member of organizations: '.$organizations : '')
        .($builds ? ', member of builds: '.$builds : ''));
    $user->update({ password => Authen::Passphrase::RejectAll->new, deactivated => \'now()' });

    $user->delete_related('user_organization_roles');
    $user->delete_related('user_build_roles');

    if ($params->{clear_tokens}) {
        $c->log->warn('user '.$c->stash('user')->name.' deleting all user session tokens for user '.$user->name);
        $user->delete_related('user_session_tokens');
    }

    return $c->status(204);
}

=head2 get_api_tokens

Get a list of unexpired tokens for the user (api only).

Response uses the UserTokens json schema.

=cut

sub get_api_tokens ($c) {
    my $rs = $c->stash('target_user')
        ->user_session_tokens
        ->api_only
        ->unexpired
        ->order_by('name');
    return $c->status(200, [ $rs->all ]);
}

=head2 create_api_token

Generate a new token, creating a JWT from it. Response uses the NewUserToken json schema.
This is the only time the token string is provided to the user, so don't lose it!

=cut

sub create_api_token ($c) {
    my $input = $c->stash('request_data');

    # we use this naming convention to indicate login tokens
    return $c->status(400, { error => 'name "'.$input->{name}.'" is reserved' })
        if $input->{name} =~ /^login_jwt_/;

    my $user = $c->stash('target_user');

    # default expiration: 5 years
    my $expires_abs = time + (($c->app->config('authentication')//{})->{custom_token_expiry} // 86400*365*5);

    my ($token, $jwt) = $c->generate_jwt($user->id, $expires_abs, $input->{name});
    return if $c->res->code;

    $c->res->headers->last_modified(Mojo::Date->new($token->created->epoch));
    $c->res->headers->expires(Mojo::Date->new($token->expires->epoch));
    $c->res_location('/user/'.($user->id eq $c->stash('user_id') ? 'me' : $user->id).'/token/'.$input->{name});

    my $token_data = $token->TO_JSON;
    delete $token_data->{last_ipaddr};
    return $c->status(201, { token => $jwt, $token_data->%* });
}

=head2 find_api_token

Chainable action that takes the C<token_name> provided in the path and looks it up in the
database, stashing a resultset to access it as C<token_rs>.

Only api tokens may be retrieved by this flow.

=cut

sub find_api_token ($c) {
    # lookup of login tokens not supported
    return $c->status(404) if $c->stash('token_name') =~ /^login_jwt_/;

    my $token_rs = $c->stash('target_user')
        ->user_session_tokens
        ->unexpired
        ->search({ name => $c->stash('token_name') });

    if (not $token_rs->exists) {
        $c->log->debug('Could not find token '.$c->stash('token_name')
            .' for user '.$c->stash('target_user')->email);
        return $c->status(404);
    }

    $c->stash('token_rs', $token_rs);
    return 1;
}

=head2 get_api_token

Get information about the specified (unexpired) api token.

Response uses the UserToken json schema.

=cut

sub get_api_token ($c) {
    return $c->status(200, $c->stash('token_rs')->single);
}

=head2 expire_api_token

Deactivates an api token from future use.

=cut

sub expire_api_token ($c) {
    $c->log->warn('user '.$c->stash('user')->name.' expired user session token "'
        .$c->stash('token_name').'" for user '.$c->stash('target_user')->name);
    $c->stash('token_rs')->expire;
    return $c->status(204);
}

1;
__END__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<https://www.mozilla.org/en-US/MPL/2.0/>.

=cut
# vim: set sts=2 sw=2 et :
