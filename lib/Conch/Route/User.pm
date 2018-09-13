package Conch::Route::User;
use Mojo::Base -strict;

use Exporter 'import';
our @EXPORT_OK = qw(user_routes);

=pod

=head1 NAME

Conch::Route::User

=head1 METHODS

=head2 user_routes

Sets up routes for /user:

    POST    /user/me/revoke
    GET     /user/me/settings
    POST    /user/me/settings
    GET     /user/me/settings/#key
    POST    /user/me/settings/#key
    DELETE  /user/me/settings/#key
    POST    /user/me/password

    GET     /user/#target_user
    POST    /user/#target_user/revoke
    DELETE  /user/#target_user/password
    GET     /user
    POST    /user
    DELETE  /user/#target_user

=cut

sub user_routes {
    my $user = shift;    # secured, under /user

    # all these routes go to the User controller
    $user->to({ controller => 'user' });

    # interfaces for user updating their own account...
    {
        # all these routes are under /user/
        my $user_me = $user->any('/me');

        # POST /user/me/revoke
        $user_me->post('/revoke')->to('#revoke_own_tokens');

        {
            my $user_me_settings = $user_me->any('/settings');

            # GET /user/me/settings
            $user_me_settings->get->to('#get_settings');
            # POST /user/me/settings
            $user_me_settings->post->to('#set_settings');

            # 'key' is extracted into the stash
            my $user_me_settings_with_key = $user_me_settings->any('/#key');

            # GET /user/me/settings/#key
            $user_me_settings_with_key->get->to('#get_setting');
            # POST /user/me/settings/#key
            $user_me_settings_with_key->post->to('#set_setting');
            # DELETE /user/me/settings/#key
            $user_me_settings_with_key->delete->to('#delete_setting');
        }

        # after changing password, (possibly) pass through to logging out too
        # POST /user/me/password
        $user_me->under('/password')->to('#change_own_password')
            ->post->to('login#session_logout');
    }

    # administrator interfaces for updating a different user's account...
    {
        # target_user could be a user id or email
        my $user_with_target = $user->require_global_admin->any('/#target_user');

        # GET /user/#target_user
        $user_with_target->get('/')->to('#get');

        # POST /user/#target_user/revoke
        $user_with_target->post('/revoke')->to('#revoke_user_tokens');
        # DELETE /user/#target_user/password
        $user_with_target->delete('/password')->to('#reset_user_password');

        # GET /user
        $user->require_global_admin->get('/')->to('#list');
        # POST /user
        $user->require_global_admin->post('/')->to('#create');
        # DELETE /user/#target_user
        $user_with_target->delete('/')->to('#deactivate');
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
