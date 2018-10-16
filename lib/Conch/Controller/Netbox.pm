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

=head2 getInterfaces

pull interfaces for a named device with the option of adding a specific interface

=cut

sub getInterfaces($c){
  my $params = $c->req->query_params;
  my $path='/dcim/interfaces/?'.$params;
  my $ret_hash=getNetbox($path);
  my $retstatus=404;
  if($ret_hash->{count}<1){
    $ret_hash=decode_json('{"error":"nothing matched your search for '.$path.'"}');
  }elsif($ret_hash->{count}>0){
    my $i=0;
    for(@{$ret_hash->{results}}){
      my $address=getIPAddress($_->{id});
      if($address){
        $ret_hash->{'results'}[$i]{'address'}=$address;
      }
      $i++;
    }
    $retstatus=200;
  }
  return $c->render(status => $retstatus,text => encode_json($ret_hash));
}

=head2 getDevice

pull device information for a specific device

=cut

sub getDevice($c){
  return $c->status(200,"It's not plugged in yet!");
}

=head2 getIPAddress

pull ip address from interface ID

=cut

sub getIPAddress{
  my $ret_hash=getNetbox('/ipam/ip-addresses/?interface_id='.$_[0]);
  if($ret_hash->{count}==1){
    return $ret_hash->{results}[0]{address};
  }
}

=head2 getNetbox

Interact with netbox dependent on auth file being in place

=cut

sub getNetbox{
  my $nb='dev';
  my $creds=hashFromFile('/opt/netbox/auth.json');
  my $server=$creds->{$nb}->{server};
  my $token=$creds->{$nb}->{token};
  my $url='https://'.$server.'/api'.$_[0];
  my %headers=("Accept"=>"application/json","Authorization"=>"Token $token");
  my %options=('headers'=>\%headers);
  my $http=HTTP::Tiny->new;
  my $request=$http->request('GET',$url,\%options);
  my $content=$request->{content};
  my $json_out = eval { decode_json($content) };
  if($@){
    return decode_json('{"error":"'.$@.'"}');
  }else{
    return $json_out
  }
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
