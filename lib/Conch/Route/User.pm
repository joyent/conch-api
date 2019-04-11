package Conch::Route::User;

use Mojo::Base -strict, -signatures;

=pod

=head1 NAME

Conch::Route::User

=head1 METHODS

=head2 routes

Sets up the routes for /user:

    GET     /user/me
    POST    /user/me/revoke
    POST    /user/me/password?clear_tokens=<login_only|0|all>
    GET     /user/me/settings
    POST    /user/me/settings
    GET     /user/me/settings/#key
    POST    /user/me/settings/#key
    DELETE  /user/me/settings/#key

    GET     /user/me/token
    POST    /user/me/token
    DELETE  /user/me/token (same as POST /user/me/revoke)
    GET     /user/me/token/:token_name
    DELETE  /user/me/token/:token_name

    GET     /user/#target_user_id_or_email
    POST    /user/#target_user_id_or_email
    DELETE  /user/#target_user_id_or_email?clear_tokens=<1|0>
    POST    /user/#target_user_id_or_email/revoke
    DELETE  /user/#target_user_id_or_email/password?clear_tokens=<login_only|0|all>&send_password_reset_mail=<1|0>

    GET     /user/#target_user_id_or_email/token
    DELETE  /user/#target_user_id_or_email/token (same as POST /user/#target_user_id_or_email/revoke)
    GET     /user/#target_user_id_or_email/token/:token_name
    DELETE  /user/#target_user_id_or_email/token/:token_name

    GET     /user
    POST    /user?send_mail=<1|0>

=cut

sub routes {
    my $class = shift;
    my $user = shift;    # secured, under /user

    # all these routes go to the User controller
    $user->to({ controller => 'user' });

    # interfaces for user updating their own account...
    {
        # all /user/me routes operate with the target user set to ourselves
        my $user_me = $user->under('/me')
            ->to(cb => sub ($c) { $c->stash('target_user', $c->stash('user')); return 1 });

        # GET /user/me
        $user_me->get('/')->to('#get');

        # POST /user/me/revoke
        $user_me->post('/revoke')->to('#revoke_user_tokens');

        # POST /user/me/password?clear_tokens=<login_only|0|all>
        # (after changing password, (possibly) pass through to logging out too)
        $user->under('/me/password')->to('#change_own_password')
            ->post('/')->to('login#session_logout');

        {
            my $user_me_settings = $user_me->any('/settings');

            # GET /user/me/settings
            $user_me_settings->get('/')->to('#get_settings');
            # POST /user/me/settings
            $user_me_settings->post('/')->to('#set_settings');

            # 'key' is extracted into the stash
            my $user_me_settings_with_key = $user_me_settings->any('/#key');

            # GET /user/me/settings/#key
            $user_me_settings_with_key->get('/')->to('#get_setting');
            # POST /user/me/settings/#key
            $user_me_settings_with_key->post('/')->to('#set_setting');
            # DELETE /user/me/settings/#key
            $user_me_settings_with_key->delete('/')->to('#delete_setting');
        }

        {
            my $user_me_token = $user_me->any('/token');

            # GET /user/me/token
            $user_me_token->get('/')->to('#get_tokens');
            # POST /user/me/token
            $user_me_token->post('/')->to('#create_token');
            # DELETE /user/me/token (same as POST /user/me/revoke)
            $user_me_token->delete('/')->to('#revoke_user_tokens');

            my $with_token = $user_me_token->under('/:token_name')->to('#find_token');

            # GET /user/me/token/:token_name
            $with_token->get('/')->to('#get_token');

            # DELETE /user/me/token/:token_name
            $with_token->delete('/')->to('#expire_token');
        }
    }

    # administrator interfaces for updating a different user's account...
    {
        # syntax: <uuid> or email=<email address>
        my $user_with_target = $user->require_system_admin->under('/#target_user_id_or_email')
            ->to('#find_user');

        # GET /user/#target_user_id_or_email
        $user_with_target->get('/')->to('#get');
        # POST /user/#target_user_id_or_email
        $user_with_target->post('/')->to('#update');
        # DELETE /user/#target_user_id_or_email?clear_tokens=<1|0>
        $user_with_target->delete('/')->to('#deactivate');

        # POST /user/#target_user_id_or_email/revoke
        $user_with_target->post('/revoke')->to('#revoke_user_tokens');
        # DELETE /user/#target_user_id_or_email/password?clear_tokens=<login_only|0|all>&send_password_reset_mail=<1|0>
        $user_with_target->delete('/password')->to('#reset_user_password');

        # GET /user
        $user->require_system_admin->get('/')->to('#list');
        # POST /user?send_mail=<1|0>
        $user->require_system_admin->post('/')->to('#create');

        {
            my $user_with_target_token = $user_with_target->any('/token');

            # GET /user/#target_user_id_or_email/token
            $user_with_target_token->get('/')->to('#get_tokens');
            # DELETE /user/#target_user_id_or_email/token (same as POST /user/#target_user_id_or_email/revoke)
            $user_with_target_token->delete('/')->to('#revoke_user_tokens');

            my $with_token = $user_with_target_token->under('/:token_name')->to('#find_token');

            # GET /user/#target_user_id_or_email/token/:token_name
            $with_token->get('/')->to('#get_token');

            # DELETE /user/#target_user_id_or_email/token/:token_name
            $with_token->delete('/')->to('#expire_token');
        }
    }
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
