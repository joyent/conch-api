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

    GET     /user/me
    POST    /user/me/revoke
    GET     /user/me/settings
    POST    /user/me/settings
    GET     /user/me/settings/#key
    POST    /user/me/settings/#key
    DELETE  /user/me/settings/#key
    POST    /user/me/password

    GET     /user/#target_user_id
    DELETE  /user/#target_user_id
    POST    /user/#target_user_id/revoke
    DELETE  /user/#target_user_id/password
    GET     /user
    POST    /user

=cut

sub user_routes {
    my $user = shift;    # secured, under /user

    # all these routes go to the User controller
    $user->to({ controller => 'user' });

    # interfaces for user updating their own account...
    {
        # all these routes are under /user/
        my $user_me = $user->any('/me');

        # GET /user/me
        $user_me->get('/')->to('#get_me');

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
        # target_user_id could be a user id or email
        my $user_with_target = $user->require_system_admin->under('/#target_user_id')
            ->to('#find_user');

        # GET /user/#target_user_id
        $user_with_target->get('/')->to('#get');
        # DELETE /user/#target_user_id
        $user_with_target->delete('/')->to('#deactivate');

        # POST /user/#target_user_id/revoke
        $user_with_target->post('/revoke')->to('#revoke_user_tokens');
        # DELETE /user/#target_user_id/password
        $user_with_target->delete('/password')->to('#reset_user_password');

        # GET /user
        $user->require_system_admin->get('/')->to('#list');
        # POST /user
        $user->require_system_admin->post('/')->to('#create');
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
