package Conch::Controller::User;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use List::Util 'pairmap';
use Mojo::JSON qw(to_json from_json);

=pod

=head1 NAME

Conch::Controller::User

=head1 METHODS

=head2 revoke_user_tokens

Revoke a specified user's tokens and prevents future token authentication,
forcing the user to /login again. By default *all* of a user's tokens are deleted,
but this can be adjusted with query parameters:

 * ?login_only=1    login tokens are removed; api tokens are left alone
 * ?api_only=1      login tokens are left alone; api tokens are removed

If login tokens are affected, C<user_session_auth> is also set for the user, which forces the
user to change his password as soon as a login token is used again (but use of any existing api
tokens is allowed).

System admin only (unless reached via /user/me).

Sends an email to the affected user, unless C<?send_mail=0> is included in the query (or
revoking for oneself).

=cut

sub revoke_user_tokens ($c) {
    my $params = $c->validate_query_params('RevokeUserTokens');
    return if not $params;

    $c->validate_request('Null');
    return if $c->res->code;

    my $login_only = $params->{login_only} // 0;
    my $api_only = $params->{api_only} // 0;

    my $user = $c->stash('target_user');
    $c->log->debug('revoking session tokens for user '.$user->name.', forcing them to /login again');

    my $send_mail = $user->id ne $c->stash('user_id') && ($params->{send_mail} // 1);

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
            From => 'noreply@conch.joyent.us',
            Subject => 'Your Conch tokens have been revoked.',
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
    my $input = $c->validate_request('UserSettings');
    return if not $input;

    my $user = $c->stash('target_user');

    # deactivate *all* settings first
    $user->related_resultset('user_settings')->active->deactivate;

    # store new settings
    $user->related_resultset('user_settings')
        ->populate([ pairmap { +{ name => $a, value => to_json($b) } } $input->%* ]);

    $c->status(204);
}

=head2 set_setting

Set the value of a single setting for the target user.

FIXME: the key name is repeated in the URL and the payload :(

=cut

sub set_setting ($c) {
    my $input = $c->validate_request('UserSetting');
    return if not $input;

    my $key = $c->stash('key');
    my $value = $input->{$key};
    return $c->status(400, { error => 'Setting key in request object must match name in the URL (\''.$key.'\')' }) if not $value;

    my $user = $c->stash('target_user');

    # FIXME? we should have a unique constraint on user_id+name
    # rather than creating additional rows.
    $user->search_related('user_settings', { name => $key })->active->deactivate;
    $user->create_related('user_settings', { name => $key, value => to_json($value) });
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
        +($_->name => from_json($_->value)),
        $c->stash('target_user')->user_settings->active->order_by('created');

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

    return $c->status(404) if not $setting;
    $c->status(200, { $key => from_json($setting->value) });
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

Optionally takes a query parameter 'clear_tokens', to also revoke session tokens for the user,
forcing the user to log in again.  Possible options are:

  * none
  * login_only (default) - clear login tokens only
  * all - clear all tokens (login and api - affects all APIs and tools)

When login tokens are cleared, the user is also logged out.

=cut

sub change_own_password ($c) {
    my $params = $c->validate_query_params('ChangePassword');
    return if not $params;

    my $input = $c->validate_request('UserPassword');
    return if not $input;

    my $clear_tokens = $params->{clear_tokens} // 'login_only';

    my $user = $c->stash('user');
    $user->update({
        password => $input->{password},
        refuse_session_auth => 0,
        force_password_change => 0,
    });

    $c->log->debug('updated password for user '.$user->name.' at their request');

    return $c->status(204) if $clear_tokens eq 'none';

    my $rs = $user->user_session_tokens;
    $rs = $rs->login_only if $clear_tokens ne 'all';
    $rs->delete;

    # processing continues with Conch::Controller::Login::session_logout
    return 1;
}

=head2 reset_user_password

Generates a new random password for a user. System admin only.

Optionally takes a query parameter 'send_mail' (defaulting to true), to send an
email to the user with the new password.

Optionally takes a query parameter 'clear_tokens', to also revoke session tokens for the user,
forcing the user to log in again.  Possible options are:

  * none
  * login_only (default)
  * all - clear all tokens (login and api - affects all APIs and tools)

If all tokens are revoked, the user must also change their password after logging in, as they
will not be able to log in with it again.

=cut

sub reset_user_password ($c) {
    my $params = $c->validate_query_params('ResetUserPassword');
    return if not $params;

    my $clear_tokens = $params->{clear_tokens} // 'login_only';

    my $user = $c->stash('target_user');
    my %update = (
        password => $c->random_string(),
    );

    if ($clear_tokens ne 'none') {
        my $rs = $user->user_session_tokens;
        $rs = $rs->login_only if $clear_tokens ne 'all';
        my $count = $rs->delete;

        $c->log->warn('user '.$c->stash('user')->name.' deleted '.$count
            .($clear_tokens eq 'all' ? ' all' : ' (primary only)')
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
        From => 'noreply@conch.joyent.us',
        Subject => 'Your Conch password has changed.',
        password => $update{password},
    ) if $params->{send_mail} // 1;

    return $c->status(204);
}

=head2 get

Gets information about a user. System admin only (unless reached via /user/me).
Response uses the UserDetailed json schema.

=cut

sub get ($c) {
    my $user = $c->stash('target_user')
        ->discard_changes({
            prefetch => { user_workspace_roles => 'workspace' },
            order_by => ['workspace.name'],
        });
    return $c->status(200, $user);
}

=head2 update

Updates user attributes. System admin only.
Sends an email to the affected user, unless C<?send_mail=0> is included in the query.

The response uses the UserError json schema for some error conditions; on success, redirects to
'GET /user/:id'.

=cut

sub update ($c) {
    my $params = $c->validate_query_params('ModifyUser');
    return if not $params;

    my $input = $c->validate_request('UpdateUser');
    return if not $input;

    if (exists $input->{email}
            and my $user = $c->db_user_accounts->active->lookup_by_email($input->{email})) {
        return $c->status(409, {
            error => 'duplicate user found',
            user => { map +($_ => $user->$_), qw(id email name created deactivated) },
        });
    }

    my $user = $c->stash('target_user');
    my %orig_columns = $user->get_columns;
    $user->set_columns($input);

    if ($params->{send_mail} // 1) {
        my %dirty_columns = $user->get_dirty_columns;
        %orig_columns = %orig_columns{keys %dirty_columns};

        if (exists $dirty_columns{is_admin}) {
            $_ = $_ ? 'true' : 'false' foreach $orig_columns{is_admin}, $dirty_columns{is_admin};
        }

        $c->send_mail(
            template_file => 'updated_user_account',
            From => 'noreply@conch.joyent.us',
            Subject => 'Your Conch account has been updated.',
            orig_data => \%orig_columns,
            new_data => \%dirty_columns,
        );
    }

    $c->log->debug('updating user '.$user->email.': '.$c->req->text);
    $user->update;

    $c->status(303, '/user/'.$user->id);
}

=head2 list

List all active users and their workspaces. System admin only.
Response uses the UsersDetailed json schema.

=cut

sub list ($c) {
    my $user_rs = $c->db_user_accounts
        ->active
        ->prefetch({ user_workspace_roles => 'workspace' });

    return $c->status(200, [ $user_rs->all ]);
}

=head2 create

Creates a user. System admin only.

Optionally takes a query parameter:

* 'send_mail' (defaulting to true), to send an email to the user with the new password

Response uses the NewUser json schema (or UserError for some error conditions).

=cut

sub create ($c) {
    my $params = $c->validate_query_params('ModifyUser');
    return if not $params;

    my $input = $c->validate_request('NewUser');
    return if not $input;

    # this would cause horrible clashes with our /user routes!
    return $c->status(400, { error => 'user name "me" is prohibited' }) if $input->{name} eq 'me';

    if (my $user = $c->db_user_accounts->active->lookup_by_email($input->{email})) {
        return $c->status(409, {
            error => 'duplicate user found',
            user => { map +($_ => $user->$_), qw(id email name created deactivated) },
        });
    }

    $input->{password} //= $c->random_string;
    $input->{is_admin} = ($input->{is_admin} ? 1 : 0);

    # password will be hashed in constructor
    my $user = $c->db_user_accounts->create($input);
    $c->log->info('created user: '.$user->name.', email: '.$user->email.', id: '.$user->id);

    if ($params->{send_mail} // 1) {
        $c->stash('target_user', $user);
        $c->send_mail(
            template_file => 'new_user_account',
            From => 'noreply@conch.joyent.us',
            Subject => 'Welcome to Conch!',
            password => $input->{password},
        );
    }

    $c->res->headers->location($c->url_for('/user/'.$user->id));
    return $c->status(201, { map +($_ => $user->$_), qw(id email name) });
}

=head2 deactivate

Deactivates a user. System admin only.

Optionally takes a query parameter 'clear_tokens' (defaulting to true), to also revoke all
session tokens for the user, which would force all tools to log in again should the account be
reactivated (for which there is no api endpoint at present).

All workspace permissions are removed and are not recoverable.

Response uses the UserError json schema on some error conditions.

=cut

sub deactivate ($c) {
    my $params = $c->validate_query_params('DeactivateUser');
    return if not $params;

    my $user = $c->stash('target_user');

    if ($user->deactivated) {
        return $c->status(410, {
            error => 'user was already deactivated',
            user => { map +($_ => $user->$_), qw(id email name created deactivated) },
        });
    }

    my $workspaces = join(', ', map $_->workspace->name.' ('.$_->role.')',
        $user->related_resultset('user_workspace_roles')->prefetch('workspace')->all);

    $c->log->warn('user '.$c->stash('user')->name.' deactivating user '.$user->name
        .($workspaces ? ', direct member of workspaces: '.$workspaces : ''));
    $user->update({ password => $c->random_string, deactivated => \'now()' });

    $user->delete_related('user_workspace_roles');

    if ($params->{clear_tokens} // 1) {
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

Create a new token, creating a JWT from it.  Response uses the NewUserToken json schema.
This is the only time the token string is provided to the user, so don't lose it!

=cut

sub create_api_token ($c) {
    my $input = $c->validate_request('NewUserToken');
    return if not $input;

    # we use this naming convention to indicate login tokens
    return $c->status(400, { error => 'name "'.$input->{name}.'" is reserved' })
        if $input->{name} =~ /^login_jwt_/;

    my $user = $c->stash('target_user');

    return $c->status(409, { error => 'name "'.$input->{name}.'" is already in use' })
        if $user->user_session_tokens->search({ name => $input->{name} })->exists;

    # default expiration: 5 years
    my $expires_abs = time + (($c->app->config('jwt') || {})->{custom_token_expiry} // 86400*365*5);

    # TODO: ew ew ew, some duplication with Conch::Controller::Login::_create_jwt.
    my ($new_db_row, $token) = $c->db_user_session_tokens->generate_for_user(
        $user->id, $expires_abs, $input->{name});

    my $jwt = Mojo::JWT->new(
        claims => { uid => $user->id, jti => $token },
        secret => $c->app->config('secrets')->[0],
        expires => $expires_abs,
    )->encode;

    $c->res->headers->location($c->url_for('/user/'
        .($user->id eq $c->stash('user_id') ? 'me' : $user->id)
        .'/token/'.$input->{name}));
    return $c->status(201, {
        token => $jwt,
        $new_db_row->TO_JSON->%*,
    });
}

=head2 find_api_token

Chainable action that takes the 'token_name' provided in the path and looks it up in the
database, stashing a resultset to access it as 'token_rs'.

Only api tokens may be retrieved by this flow.

=cut

sub find_api_token ($c) {
    return $c->status(404) if $c->stash('token_name') =~ /^login_jwt_/;
    my $token_rs = $c->stash('target_user')
        ->user_session_tokens
        ->unexpired
        ->search({ name => $c->stash('token_name') });

    if (not $token_rs->exists) {
        $c->log->debug('Could not find token named "'.$c->stash('token_name')
            .' for user_id '.$c->stash('target_user')->id);
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
one at L<http://mozilla.org/MPL/2.0/>.

=cut
# vim: set ts=4 sts=4 sw=4 et :
