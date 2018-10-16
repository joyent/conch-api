=pod

=head1 NAME

Conch::Controller::Netbox

=head1 METHODS

=cut

package Conch::Controller::Netbox;

use Role::Tiny::With;
use Mojo::Base 'Mojolicious::Controller', -signatures;
use Mojo::JSON;
use Conch::UUID 'is_uuid';
use List::Util 'none', 'any';
use HTTP::Tiny;
use Try::Tiny;
use Path::Tiny;
use JSON::PP;


with 'Conch::Role::MojoLog';

use Conch::Models;

=head2 getAny

pull any netbox api path e.g. /dcmi/devices/?name=test

=cut

sub getDCIM($c){
  my $path='/dcim/'.$c->stash('path').'/?'.$c->req->query_params;
  #return $c->render(status => 200,text => $path);
  my $ret_hash=getNetbox($path);
  my $retstatus=200;
  $retstatus=404 if $ret_hash->{error};
  return $c->render(json => $ret_hash);
}

sub getIPMI($c){
  my $device=$c->stash('device_id');
  my $path='/dcim/interfaces/?device='.$device;
  my $ret_hash=getNetbox($path);
  if($ret_hash->{error}){
    return $c->render(json => $ret_hash);
  }else{
    my $ipmi;
    for(@{$ret_hash->{results}}){
      my $int=$_;
      if($int->{name} =~ /ipmi/){
        $ipmi=$int->{address};
      }
    }
    if($ipmi){
      return $c->render(text => '{"ipmi":"'.$ipmi.'"}');
    }else{
      return $c->render(text => '{"error":"No IPMI found for '.$device.'"}');
    }
  }
}

=head2 getNetbox

Interact with netbox
This currently requires that the necessary auth file is present in /opt/netbox/auth.json
and follows the following format
{"dcimname":{"server":"server name or ip","token":"token value"}}
There is probably a more suitable place for this but this will suffice until
I can get input from the team

=cut

sub getNetbox{
  my $nb='dev';
  my $path=$_[0];
  my $creds=hashFromFile('/opt/netbox/auth.json');
  my $server=$creds->{$nb}->{server};
  my $token=$creds->{$nb}->{token};
  my $url='https://'.$server.'/api'.$path;
  my %headers=("Accept"=>"application/json","Authorization"=>"Token $token");
  my %options=('headers'=>\%headers);
  my $http=HTTP::Tiny->new;
  my $request=$http->request('GET',$url,\%options);
  my $content=$request->{content};
  my $json_out = eval { decode_json($content) };
  $json_out->{netboxAPIurl}=$url;
  if($@){
    $json_out = decode_json('{"error":"No JSON Returned for:'.$path.'"}');
  }elsif($json_out->{count}<1){
    $json_out->{error}="nothing matched your search";
  }elsif($path=~/\/interfaces\//){
    my $i=0;
    for(@{$json_out->{results}}){
      my $ret_hash=getNetbox('/ipam/ip-addresses/?interface_id='.$_->{id});
      my $address=$ret_hash->{results}[0]{address};
      if($address){
        $json_out->{'results'}[$i]{'address'}=$address;
      }
      $i++;
    }
  }
  return $json_out;
}

sub hashFromFile{
  my ($file)=@_;
  my $hash=();
  my $fp = path($file);
  if ( -f $file ) {
    my $json = $fp->slurp_utf8;
    $hash = decode_json $json;
  }
  return $hash;
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
