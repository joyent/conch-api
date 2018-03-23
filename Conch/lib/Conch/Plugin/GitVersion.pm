=pod

=head1 NAME

Conch::Plugin::GitVersion

=head1 DESCRIPTION

Mojo plugin registering the git version tag and hash for the repository

=head1 METHODS

=cut

package Conch::Plugin::GitVersion;

use Mojo::Base 'Mojolicious::Plugin', -signatures;

=head2 register

Register C<version_tag> and C<version_hash>.

=cut

sub register ( $self, $app, $conf ) {
	my $git_tag = `git describe`;
	chomp $git_tag;
	my $git_hash = `git rev-parse HEAD`;
	chomp $git_hash;

	$app->helper(
		version_tag  => sub { $git_tag },
		version_hash => sub { $git_hash }
	);
}

1;
