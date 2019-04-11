package Conch::Controller::User;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Role::Tiny::With;
with 'Conch::Role::MojoLog';

use Mojo::Exception;
use List::Util 'pairmap';
use Mojo::JSON qw(to_json from_json);
use Conch::UUID 'is_uuid';
use Email::Valid;

=pod

=head1 NAME

Conch::Controller::User

=head1 METHODS

=head2 revoke_user_tokens

Revoke *all* of a specified user's session tokens and prevents future session authentication,
forcing the user to /login again.

System admin only (unless reached via /user/me).

=cut

sub revoke_user_tokens ($c) {
	my $user = $c->stash('target_user');

	$c->log->debug('revoking session tokens for user ' . $user->name . ', forcing them to /login again');
    $user->user_session_tokens->unexpired->expire;
	$user->update({ refuse_session_auth => 1 });

	$c->status(204);
}

=head2 set_settings

Override the settings for a user with the provided payload

=cut

sub set_settings ($c) {
    my $input = $c->validate_input('UserSettings');
    return if not $input;

    my $user = $c->stash('target_user');
	Mojo::Exception->throw('Could not find previously stashed user')
		unless $user;

	# deactivate *all* settings first
	$user->related_resultset('user_settings')->active->deactivate;

	# store new settings
	$user->related_resultset('user_settings')
		->populate([ pairmap { +{ name => $a, value => to_json($b) } } $input->%* ]);

	$c->status(200);
}

=head2 set_setting

Set the value of a single setting for the target user.

FIXME: the key name is repeated in the URL and the payload :(

=cut

sub set_setting ($c) {
    my $input = $c->validate_input('DeviceSetting');
    return if not $input;

	my $key   = $c->stash('key');
	my $value = $input->{$key};
	return $c->status(
		400,
		{
			error =>
				"Setting key in request object must match name in the URL ('$key')"
		}
	) unless $value;

    my $user = $c->stash('target_user');
	Mojo::Exception->throw('Could not find previously stashed user')
		unless $user;

	# FIXME? we should have a unique constraint on user_id+name
	# rather than creating additional rows.

	$user->search_related('user_settings', { name => $key })->active->deactivate;

	my $setting = $user->create_related('user_settings', {
		name => $key,
		value => to_json($value),
	});

	if ($setting) {
		return $c->status(200);
	}
	else {
		return $c->status( 500, "Failed to set setting" );
	}
}

=head2 get_settings

Get the key/values of every setting for a user.

=cut

sub get_settings ($c) {
    my $user = $c->stash('target_user');
	Mojo::Exception->throw('Could not find previously stashed user')
		unless $user;

	# turn user_setting db rows into name => value entries,
	# newer entries overwriting older ones
	my %output = map {
		$_->name => from_json($_->value)
	} $user->user_settings->active->search(undef, { order_by => 'created' });

	$c->status( 200, \%output );
}

=head2 get_setting

Get the individual key/value pair for a setting for the target user.

=cut

sub get_setting ($c) {
	my $key = $c->stash('key');

    my $user = $c->stash('target_user');
	Mojo::Exception->throw('Could not find previously stashed user')
		unless $user;

	my $setting = $user->user_settings->active->search(
		{ name => $key },
		{ order_by => { -desc => 'created' } },
	)->one_row;

	return $c->status(404) unless $setting;

	$c->status( 200, { $key => from_json($setting->value) } );
}

=head2 delete_setting

Delete a single setting for a user, provided it was set previously.

=cut

sub delete_setting ($c) {
	my $key = $c->stash('key');

    my $user = $c->stash('target_user');
	Mojo::Exception->throw('Could not find previously stashed user')
		unless $user;

	my $count = $user->search_related('user_settings', { name => $key })->active->deactivate;

	return $c->status(404) unless $count;

	return $c->status(204);
}

=head2 change_own_password

Stores a new password for the current user.

Optionally takes a query parameter 'clear_tokens', to also revoke session tokens for the user,
forcing the user to log in again.  Possible options are:

  * 0, no, false
  * login_only (default) (for backcompat, '1' is treated as login_only)
  * all - also affects all APIs and tools

=cut

sub change_own_password ($c) {
    my $input = $c->validate_input('UserPassword');
    return if not $input;

    my $clear_tokens = $c->req->query_params->param('clear_tokens') // 'login_only';
    return $c->status(400, { error => 'unrecognized "clear_tokens" value "'.$clear_tokens.'"' })
        if $clear_tokens and $clear_tokens !~ /^0|no|false|1|login_only|all$/;

    my $new_password = $input->{password};

	my $user = $c->stash('user');
	Mojo::Exception->throw('Could not find previously stashed user')
		unless $user;

	$user->update({
		password => $new_password,
		refuse_session_auth => 0,
		force_password_change => 0,
	});

	$c->log->debug('updated password for user ' . $user->name . ' at their request');

    return $c->status(204) if not $clear_tokens or $clear_tokens eq 'no' or $clear_tokens eq 'false';

    my $rs = $c->stash('user')->user_session_tokens;
    $rs = $rs->login_only if $clear_tokens ne 'all';
    $rs->delete;

	# processing continues with Conch::Controller::Login::session_logout
	return 1;
}

=head2 reset_user_password

Generates a new random password for a user. System admin only.

Optionally takes a query parameter 'send_password_reset_mail' (defaulting to true), to send an
email to the user with the new password.

Optionally takes a query parameter 'clear_tokens', to also revoke session tokens for the user,
forcing the user to log in again.  Possible options are:

  * 0, no, false
  * login_only (default) (for backcompat, '1' is treated as login_only)
  * all - also affects all APIs and tools

If all tokens are revoked, the user must also change their password after logging in, as they
will not be able to log in with it again.

=cut

sub reset_user_password ($c) {
    my $clear_tokens = $c->req->query_params->param('clear_tokens') // 'login_only';
    return $c->status(400, { error => 'unrecognized "clear_tokens" value "'.$clear_tokens.'"' })
        if $clear_tokens and $clear_tokens !~ /^0|no|false|1|login_only|all$/;

    my $user = $c->stash('target_user');
	my %update = (
		password => $c->random_string(),
	);

    if ($clear_tokens and $clear_tokens ne 'no' and $clear_tokens ne 'false') {
        my $rs = $user->user_session_tokens;
        $rs = $rs->login_only if $clear_tokens ne 'all';
        my $count = $rs->delete;
        $c->log->warn('user '.$c->stash('user')->name.' deleted '.$count
            .($clear_tokens eq 'all' ? ' all' : ' (primary only)')
            .' user session tokens for user ' . $user->name);

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

	$c->log->warn('user ' . $c->stash('user')->name . ' resetting password for user ' . $user->name);
	$user->update(\%update);

	return $c->status(204) if not $c->req->query_params->param('send_password_reset_mail') // 1;

	$c->log->info('sending "password was changed" mail to user ' . $user->name);
	$c->send_mail(changed_user_password => {
		name     => $user->name,
		email    => $user->email,
		password => $update{password},
	});
	return $c->status(202);
}

=head2 find_user

Chainable action that validates the user_id or email address (prefaced with 'email=') provided
in the path, and stashes the corresponding user row in C<target_user>.

=cut

sub find_user ($c) {
    my $user_param = $c->stash('target_user_id_or_email');

	return $c->status(400, { error => 'invalid identifier format for '.$user_param })
		if not is_uuid($user_param)
			and not ($user_param =~ /^email\=/ and Email::Valid->address($'));

	my $user_rs = $c->db_user_accounts;

	# when deactivating users or removing users from a workspace, we want to find
	# already-deactivated users too.
	$user_rs = $user_rs->active if $c->req->method ne 'DELETE';

	$c->log->debug('looking up user '.$user_param);
	my $user = $user_rs->lookup_by_id_or_email($user_param);

	return $c->status(404) if not $user;

	$c->stash('target_user', $user);
	return 1;
}

=head2 get

Gets information about a user. System admin only (unless reached via /user/me).
Response uses the UserDetailed json schema.

=cut

sub get ($c) {
	my $user = $c->stash('target_user')
		->discard_changes({ prefetch => { user_workspace_roles => 'workspace' } });
	return $c->status(200, $user);
}

=head2 update

Updates user attributes. System admin only.

Response uses the UserDetailed json schema.

=cut

sub update ($c) {
	my $input = $c->validate_input('UpdateUser');
	return if not $input;

	my $user = $c->stash('target_user');
	$c->log->debug('updating user '.$user->email.': '.$c->req->text);
	$user->update($input);

	$user->discard_changes({ prefetch => { user_workspace_roles => 'workspace' } });
	return $c->status(200, $user);
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

=cut

sub create ($c) {
    my $input = $c->validate_input('NewUser');
    return if not $input;

    my $name = $input->{name} // $input->{email};
    my $email = $input->{email};

	# this would cause horrible clashes with our /user routes!
	return $c->status(400, { error => 'user name "me" is prohibited', }) if $name eq 'me';

	if (my $user = $c->db_user_accounts->active->lookup_by_id_or_email("email=$email")) {
		return $c->status(409, {
			error => 'duplicate user found',
			user => { map { $_ => $user->$_ } qw(id email name created deactivated) },
		});
	}

	my $password = $input->{password} // $c->random_string;

	my $user = $c->db_user_accounts->create({
		name => $name,
		email => $email,
		password => $password,	# will be hashed in constructor
		is_admin => ($input->{is_admin} ? 1 : 0),
	});
	$c->log->info('created user: ' . $user->name . ', email: ' . $user->email . ', id: ' . $user->id);

	if ($c->req->query_params->param('send_mail') // 1) {
		$c->log->info('sending "welcome new user" mail to user ' . $user->name);
		$c->send_mail(welcome_new_user => {
			(map { $_ => $user->$_ } qw(name email)),
			password => $password,
		});
	}

	return $c->status(201, { map { $_ => $user->$_ } qw(id email name) });
}

=head2 deactivate

Deactivates a user. System admin only.

Optionally takes a query parameter 'clear_tokens' (defaulting to true), to also revoke all
session tokens for the user, forcing all tools to log in again.

All workspace permissions are removed and are not recoverable.

=cut

sub deactivate ($c) {
	my $user = $c->stash('target_user');

	if ($user->deactivated) {
		return $c->status(410, {
			error => 'user was already deactivated',
			user => { map { $_ => $user->$_ } qw(id email name created deactivated) },
		});
	}

	my $workspaces = join(', ', map { $_->workspace->name . ' (' . $_->role . ')' }
		$user->related_resultset('user_workspace_roles')->prefetch('workspace')->all);

	$c->log->warn('user ' . $c->stash('user')->name . ' deactivating user ' . $user->name
		. ($workspaces ? ", direct member of workspaces: $workspaces" : ''));
	$user->update({ password => $c->random_string, deactivated => \'NOW()' });

	$user->delete_related('user_workspace_roles');

	if ($c->req->query_params->param('clear_tokens') // 1) {
		$c->log->warn('user ' . $c->stash('user')->name . ' deleting all user session tokens for user ' . $user->name);
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

=cut

sub create_api_token ($c) {
    my $input = $c->validate_input('NewUserToken');
    return if not $input;

    # we use this naming convention to indicate login tokens
    return $c->status(400, { error => 'name "'.$input->{name}.'" is reserved' })
        if $input->{name} =~ /^login_jwt_/;

    my $user = $c->stash('target_user');

    return $c->status(400, { error => 'name "'.$input->{name}.'" is already in use' })
        if $user->user_session_tokens->search({ name => $input->{name} })->exists;

    # default expiration: 5 years
    my $expires_abs = time + (($c->config('jwt') || {})->{custom_token_expiry} // 86400*365*5);

    # TODO: ew ew ew, some duplication with Conch::Controller::Login::_create_jwt.
    my ($new_db_row, $token) = $c->db_user_session_tokens->generate_for_user(
        $user->id, $expires_abs, $input->{name});

    my $jwt = Mojo::JWT->new(
        claims => { uid => $user->id, jti => $token },
        secret => $c->config('secrets')->[0],
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
one at http://mozilla.org/MPL/2.0/.

=cut
