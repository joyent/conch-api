package Conch::Route::User;

use Mojo::Base -strict, -signatures;

=pod

=head1 NAME

Conch::Route::User

=head1 METHODS

=head2 routes

Sets up the routes for /user.

=cut

sub routes {
    my $class = shift;
    my $user = shift;    # secured, under /user

    # all these routes go to the User controller
    $user->to({ controller => 'user' });

    # interfaces for user updating their own account...
    {
        # all /user/me routes operate with the target user set to ourselves
        my $user_me = $user->under('/me', sub ($c) { $c->stash('target_user', $c->stash('user')); return 1 });

        # GET /user/me
        $user_me->get('/')->to('#get');

        # POST /user/me?send_mail=<1|0>
        $user_me->post('/')->to('#update', query_params_schema => 'NotifyUsers', request_schema => 'UpdateUser');

        # POST /user/me/revoke?send_mail=<1|0>&login_only=<0|1>&api_only=<0|1>
        $user_me->post('/revoke')->to('#revoke_user_tokens', query_params_schema => 'RevokeUserTokens', request_schema => 'Null');

        # POST /user/me/password?clear_tokens=<login_only|none|all>
        # (after changing password, (possibly) pass through to logging out too)
        $user->under('/me/password')->to('#change_own_password', query_params_schema => 'ChangePassword', request_schema => 'UserPassword')
            ->post('/')->to('login#logout');

        {
            my $user_me_settings = $user_me->any('/settings');

            # GET /user/me/settings
            $user_me_settings->get('/')->to('#get_settings');
            # POST /user/me/settings
            $user_me_settings->post('/')->to('#set_settings', request_schema => 'UserSettings');

            # 'key' is extracted into the stash
            my $user_me_settings_with_key = $user_me_settings->any('/#key');

            # GET /user/me/settings/#key
            $user_me_settings_with_key->get('/')->to('#get_setting');
            # POST /user/me/settings/#key
            $user_me_settings_with_key->post('/')->to('#set_setting', request_schema => 'UserSetting');
            # DELETE /user/me/settings/#key
            $user_me_settings_with_key->delete('/')->to('#delete_setting');
        }

        {
            my $user_me_token = $user_me->any('/token');

            # GET /user/me/token
            $user_me_token->get('/')->to('#get_api_tokens');
            # POST /user/me/token
            $user_me_token->post('/')->to('#create_api_token', request_schema => 'NewUserToken');

            # note: because we use a wildcard placeholder for token_name, nothing else
            # can be added to the route after the name.
            my $with_token = $user_me_token->under('/*token_name')->to('#find_api_token');

            # GET /user/me/token/*token_name
            $with_token->get('/')->to('#get_api_token');

            # DELETE /user/me/token/*token_name
            $with_token->delete('/')->to('#expire_api_token');
        }
    }

    # administrator interfaces for updating a different user's account...
    {
        # this value can be a user_id or an email address
        my $user_with_target = $user->require_system_admin->under('/#target_user_id_or_email')
            ->to('#find_user');

        # GET /user/#target_user_id_or_email
        $user_with_target->get('/')->to('#get');
        # POST /user/#target_user_id_or_email?send_mail=<1|0>
        $user_with_target->post('/')->to('#update', query_params_schema => 'NotifyUsers', request_schema => 'UpdateUser');
        # DELETE /user/#target_user_id_or_email?clear_tokens=<1|0>
        $user_with_target->delete('/')->to('#deactivate', query_params_schema => 'DeactivateUser');

        # POST /user/#target_user_id_or_email/revoke?login_only=<0|1>&api_only=<0|1>
        $user_with_target->post('/revoke')->to('#revoke_user_tokens', query_params_schema => 'RevokeUserTokens', request_schema => 'Null');
        # DELETE /user/#target_user_id_or_email/password?clear_tokens=<login_only|none|all>&send_mail=<1|0>
        $user_with_target->delete('/password')->to('#reset_user_password', query_params_schema => 'ResetUserPassword');

        # GET /user
        $user->require_system_admin->get('/')->to('#get_all');
        # POST /user?send_mail=<1|0>
        $user->require_system_admin->post('/')->to('#create', query_params_schema => 'NotifyUsers', request_schema => 'NewUser');

        {
            my $user_with_target_token = $user_with_target->any('/token');

            # GET /user/#target_user_id_or_email/token
            $user_with_target_token->get('/')->to('#get_api_tokens');

            # note: because we use a wildcard placeholder for token_name, nothing else
            # can be added to the route after the name.
            my $with_token = $user_with_target_token->under('/*token_name')->to('#find_api_token');

            # GET /user/#target_user_id_or_email/token/*token_name
            $with_token->get('/')->to('#get_api_token');

            # DELETE /user/#target_user_id_or_email/token/*token_name
            $with_token->delete('/')->to('#expire_api_token');
        }
    }
}

1;
__END__

=pod

=head1 ROUTE ENDPOINTS

All routes require authentication.

=head2 C<GET /user/me>

=over 4

=item * Controller/Action: L<Conch::Controller::User/get>

=item * Response: F<response.yaml#/$defs/UserDetailed>

=back

=head2 C<< POST /user/:target_user_id_or_email?send_mail=<1|0> >>

Optionally take the query parameter C<send_mail> (defaults to C<1>) to send
an email telling the user their account was updated

=over 4

=item * Controller/Action: L<Conch::Controller::User/update>

=item * Request: F<request.yaml#/$defs/UpdateUser>

=item * Success Response: Redirect to the user that was updated

=item * Error response on duplicate user: F<response.yaml#/$defs/UserError> (only if the
calling user is a system admin)

=back

=head2 C<< POST /user/me/revoke?send_mail=<1|0>&login_only=<0|1>&api_only=<0|1> >>

Optionally accepts the following query parameters:

=over 4

=item * C<< send_mail=<1|0> >> (default C<1>) - send an email telling the user their tokens were revoked

=item * C<< login_only=<0|1> >> (default C<0>) - revoke only login/session tokens

=item * C<< api_only=<0|1> >> (default C<0>) - revoke only API tokens

=back

By default it will revoke both login/session and API tokens.
C<api_only> and C<login_only> cannot both be C<1>.

=over 4

=item * Controller/Action: L<Conch::Controller::User/revoke_user_tokens>

=item * Request: F<request.yaml#/$defs/UserSettings>

=item * Response: C<204 No Content>

=back

=head2 C<< POST /user/me/password?clear_tokens=<login_only|none|all> >>

Optionally takes a query parameter C<clear_tokens>, to also revoke the session
tokens for the user, forcing the user to log in again. Possible options are:

=over 4

=item * C<none>

=item * C<login_only>

=item * C<all> - clear all tokens (login and api - affects all APIs and tools)

=back

If the C<clear_tokens> parameter is set to C<none> then the user session will remain;
otherwise, the user is logged out.

=over 4

=item * Controller/Action: L<Conch::Controller::User/change_own_password>

=item * Request: F<request.yaml#/$defs/UserSettings>

=item * Response: C<204 No Content>

=back


=head2 C<GET /user/me/settings>

=over 4

=item * Controller/Action: L<Conch::Controller::User/get_settings>

=item * Response: F<response.yaml#/$defs/UserSettings>

=back

=head2 C<POST /user/me/settings>

=over 4

=item * Controller/Action: L<Conch::Controller::User/set_settings>

=item * Request: F<request.yaml#/$defs/UserSettings>

=item * Response: C<204 No Content>

=back

=head2 C<GET /user/me/settings/:key>

=over 4

=item * Controller/Action: L<Conch::Controller::User/get_setting>

=item * Response: F<response.yaml#/$defs/UserSetting>

=back

=head2 C<POST /user/me/settings/:key>

=over 4

=item * Controller/Action: L<Conch::Controller::User/set_setting>

=item * Request: F<request.yaml#/$defs/UserSetting>

=item * Response: C<204 No Content>

=back

=head2 C<DELETE /user/me/settings/:key>

=over 4

=item * Controller/Action: L<Conch::Controller::User/delete_setting>

=item * Response: C<204 No Content>

=back

=head2 C<GET /user/me/token>

=over 4

=item * Controller/Action: L<Conch::Controller::User/get_api_tokens>

=item * Response: F<response.yaml#/$defs/UserTokens>

=back

=head2 C<POST /user/me/token>

=over 4

=item * Controller/Action: L<Conch::Controller::User/create_api_token>

=item * Request: F<request.yaml#/$defs/NewUserToken>

=item * Response: F<response.yaml#/$defs/NewUserToken>

=back

=head2 C<GET /user/me/token/:token_name>

=over 4

=item * Controller/Action: L<Conch::Controller::User/get_api_token>

=item * Response: F<response.yaml#/$defs/UserToken>

=back

=head2 C<DELETE /user/me/token/:token_name>

=over 4

=item * Controller/Action: L<Conch::Controller::User/expire_api_token>

=item * Response: C<204 No Content>

=back

=head2 C<GET /user/:target_user_id_or_email>

=over 4

=item * Requires system admin authorization (when updating a different account than one's own)

=item * Controller/Action: L<Conch::Controller::User/get>

=item * Response: F<response.yaml#/$defs/UserDetailed>

=back

=head2 C<< POST /user/:target_user_id_or_email?send_mail=<1|0> >>

Optionally take the query parameter C<send_mail> (defaults to C<1>) to send
an email telling the user their account was updated

=over 4

=item * Requires system admin authorization

=item * Controller/Action: L<Conch::Controller::User/update>

=item * Request: F<request.yaml#/$defs/UpdateUser>

=item * Success Response: Redirect to the user that was updated

=item * Error response on duplicate user: F<response.yaml#/$defs/UserError> (only if the
calling user is a system admin)

=back

=head2 C<< DELETE /user/:target_user_id_or_email?clear_tokens=<1|0> >>

When a user is deleted, all role entries (build, organization) are removed and are
unrecoverable.

Optionally takes a query parameter C<clear_tokens> (defaults to C<1>), to also
revoke all session tokens for the user forcing all tools to log in again.

=over 4

=item * Requires system admin authorization

=item * Controller/Action: L<Conch::Controller::User/deactivate>

=item * Response: C<204 No Content>

=back

=head2 C<< POST /user/:target_user_id_or_email/revoke?login_only=<0|1>&api_only=<0|1> >>

Optionally accepts the following query parameters:

=over 4

=item * C<< login_only=<0|1> >> (default C<0>) - revoke only login/session tokens

=item * C<< api_only=<0|1> >> (default C<0>) - revoke only API tokens

=back

By default it will revoke both login/session and API tokens. If both
C<api_only> and C<login_only> cannot both be C<1>.

=over 4

=item * Requires system admin authorization

=item * Controller/Action: L<Conch::Controller::User/revoke_user_tokens>

=item * Response: C<204 No Content>

=back

=head2 C<< DELETE /user/:target_user_id_or_email/password?clear_tokens=<login_only|none|all>&send_mail=<1|0> >>

Optionally accepts the following query parameters:

=over 4

=item * C<clear_tokens> (default C<login_only>) to also revoke tokens for the user, takes the following possible values:

=over 4

=item * C<none>

=item * C<login_only>

=item * C<all> - clear all tokens (login and api - affects all APIs and tools)

=back

=item * C<send_mail> which takes C<< <1|0> >> (defaults to C<1>) to send an email to the user with password reset instructions.

=back

=over 4

=item * Requires system admin authorization

=item * Controller/Action: L<Conch::Controller::User/reset_user_password>

=item * Response: C<204 No Content>

=back

=head2 C<GET /user>

=over 4

=item * Requires system admin authorization

=item * Controller/Action: L<Conch::Controller::User/get_all>

=item * Response: F<response.yaml#/$defs/Users>

=back

=head2 C<< POST /user?send_mail=<1|0> >>

Optionally takes a query parameter, C<send_mail> (defaults to C<1>) to send an
email to the user with the new password.

=over 4

=item * Requires system admin authorization

=item * Controller/Action: L<Conch::Controller::User/create>

=item * Request: F<request.yaml#/$defs/NewUser>

=item * Success Response: F<response.yaml#/$defs/NewUser>

=item * Error response on duplicate user: F<response.yaml#/$defs/UserError>

=back

=head2 C<GET /user/:target_user_id_or_email/token>

=over 4

=item * Requires system admin authorization

=item * Controller/Action: L<Conch::Controller::User/get_api_tokens>

=item * Response: F<response.yaml#/$defs/UserTokens>

=back

=head2 C<GET /user/:target_user_id_or_email/token/:token_name>

=over 4

=item * Requires system admin authorization

=item * Controller/Action: L<Conch::Controller::User/get_api_token>

=item * Response: F<response.yaml#/$defs/UserTokens>

=back

=head2 C<DELETE /user/:target_user_id_or_email/token/:token_name>

=over 4

=item * Requires system admin authorization

=item * Controller/Action: L<Conch::Controller::User/expire_api_token>

=item * Success Response: C<204 No Content>

=item * Error response when user already deactivated: F<response.yaml#/$defs/UserError>

=back

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<https://www.mozilla.org/en-US/MPL/2.0/>.

=cut
# vim: set ts=4 sts=4 sw=4 et :
