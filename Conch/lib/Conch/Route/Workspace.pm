package Conch::Route::Workspace;
use Mojo::Base -strict;

use Exporter 'import';
our @EXPORT = qw(
  workspace_routes
);

sub workspace_routes {
  my $r = shift;

  $r->get('/workspace')->to('workspace#list');
  $r->get('/workspace/:id')->to('workspace#get');

  # routes namespaced under a specific workspace
  my $in_workspace = $r->under('/workspace/:id')->to('workspace#under');

  $in_workspace->get('/child')->to('workspace#get_sub_workspaces');
  $in_workspace->post('/child')->to('workspace#create_sub_workspace');

  $in_workspace->get('/device')->to('workspace_device#list');

# Redirect /workspace/:id/device/active to use query parameter on /workspace/:id/device
  $in_workspace->get(
    '/device/active',
    sub {
      my $c    = shift;
      my @here = @{ $c->url_for->path->parts };
      pop @here;
      $c->redirect_to(
        $c->url_for( join( '/', @here ) )->query( active => 't' )->to_abs );
    }
  );

  $in_workspace->get('/problem')->to('workspace_problem#list');

  $in_workspace->get('/rack')->to('workspace_rack#list');
  $in_workspace->post('/rack')->to('workspace_rack#add');

  my $with_workspace_rack =
    $in_workspace->under('/rack/:rack_id')->to('workspace_rack#under');

  $with_workspace_rack->get('')->to('workspace_rack#get_layout');
  $with_workspace_rack->delete('')->to('workspace_rack#remove');
  $with_workspace_rack->post('/layout')->to('workspace_rack#assign_layout');

  $in_workspace->get('/room')->to('workspace_room#list');
  $in_workspace->put('/room')->to('workspace_room#replace_rooms');

  $in_workspace->get('/relay')->to('workspace_relay#list');

  $in_workspace->get('/user')->to('workspace_user#list');
  $in_workspace->post('/user')->to('workspace_user#invite');
}

1;
