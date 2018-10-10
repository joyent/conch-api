package Conch::Plugin::ApiVersion;

use Mojo::Base 'Mojolicious::Plugin', -signatures;

=head2 register

Load the plugin into Mojo. Called by Mojo directly

=cut

use constant API_CURRENT_VERSION    => '2.1.0';
use constant API_SUPPORTED_VERSIONS => [
	API_CURRENT_VERSION,
	'2.0.0',
];

sub register ( $self, $app, $conf ) {
	$app->routes->get('/ping', sub ($c) {
		$c->status( 200 => {
			status        => 'ok', # for back compat with pre-versioning clients
			ping          => 'pong',
			conchapi      => {
				versions  => API_SUPPORTED_VERSIONS,
			},
		})
	});

	$app->hook(before_routes => sub ($c) {
		my $accepts = $c->req->headers->to_hash->{'Accept-Version'} // '*';
		if (_client_accepts($accepts, API_SUPPORTED_VERSIONS)) {
			$c->stash(client_accepted_versions => $accepts);
		} else {
			return $c->status(406 => "Cannot service the requested version");
		}
	});

	$app->hook(after_render => sub ($c, $output, $format) {
		$c->res->headers->append("api-version" => API_CURRENT_VERSION);
		$c->res->headers->append("server" => $c->version_tag());
	});

	$app->helper(client_accepts => sub ($c, $version) {
		return _client_accepts($c->stash('client_accepted_versions'), $version);
	});

}

# The rule syntax, per https://github.com/npm/node-semver#ranges, looks like
# ">2.1.0 <2.3.0||~3
# Translation: if the api supports data versions greater than 2.1 and less than
# 2.3 OR if the api supports data versions with a major number of 3
# Not providing an accept header or providing "*" is YOLOing it and taking
# whatever the API has currently.
sub _client_accepts($accept, $versions) {
	if ((not $accept) or ($accept eq '*')) {
		return 1;
	}
	if (ref($versions) eq 'ARRAY') {
		$versions = [ $versions ];
	}
	
	my $current = API_CURRENT_VERSION;
	my @comparators = split(/\|\|/, $accept);
	
	COMPARE: for my $compare (@comparators) {
		my @set = split(/\s/, $compare);
		my $matches = 0;
		for my $set (@set) {
			$set =~ s/^(.*?)(\d)/$2/;
			my $rule = $1 eq "" ? "=" : $1;
			my $rule_version = $set;

			if($rule eq '=') {
				if($rule_version eq $current) {
					$matches++;
				} else {
					next COMPARE;
				}
			}
			if($matches == scalar(@set)) { return 1; }
		}
	}
	return 0;
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
