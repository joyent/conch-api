package Conch::Model::User;
use Mojo::Base -base, -signatures;

use Crypt::Eksblowfish::Bcrypt qw(bcrypt en_base64);
use Data::Validate::UUID qw(is_uuid);

use Data::Printer;

has [qw(
	email
	id
	name
	password_hash
	pg
)];

sub _BCRYPT_COST { 4 } # dancer2 legacy

sub as_v1 ( $self ) {
	{
		id    => $self->id,
		email => $self->email,
		name  => $self->name,
	}
}


sub create ( $class, $pg, $email, $password ) {
	my $password_hash = _hash_password($password);

	my $ret = $pg->db->select(
		'user_account',
		[ 'id' ],
		{ email => $email },
	)->rows;
	return undef if $ret;

	$ret = $pg->db->insert(
		'user_account', {
			email         => $email,
			password_hash => $password_hash,
			name          => $email
		},
		{  returning => [qw(id)], }
	)->hash;

	return undef unless ($ret && $ret->{id});
	return $class->new(
		pg    => $pg,
		id    => $ret->{id},
		email => $email,
		name  => $email,
		password_hash => $password_hash,
	);
}

sub lookup ( $class, $pg, $id ) {
	my $where = {};
	my $ret;
	if (is_uuid($id)) {
		$ret = $pg->db->select(
			'user_account',
			undef,
			{ id => $id },
		)->hash;
	} else {
		$ret = $pg->db->select(
			'user_account',
			undef,
			{ name => $id },
		)->hash;

		unless ($ret) {
			$ret = $pg->db->select(
				'user_account',
				undef,
				{ email => $id },
			)->hash;
		}
	}

	return undef unless $ret;

	$ret->{password_hash} =~ s/^{CRYPT}//; # ohai dancer
	return $class->new(
		pg    => $pg,
		id    => $ret->{id},
		email => $ret->{email},
		name  => $ret->{name},
		password_hash => $ret->{password_hash},
	);
}

sub lookup_by_email ( $class, $pg, $email ) {
	return $class->lookup($pg, $email);
}

sub lookup_by_name ($class, $pg, $name ) {
	return $class->lookup($pg, $name);
}

sub update_password ( $self, $p ) {
	my $password_hash = _hash_password($p);
	my $ret = $self->pg->db->update(
		'user_account',
		{ password_hash => $password_hash },
		{ id            => $self->id }
	);
	if (scalar $ret->rows) {
		$self->password_hash($password_hash);
		return 1;
	}
	return 0;
}

sub validate_password ($self, $p) {
	if($self->password_hash eq bcrypt($p, $self->password_hash)) {
		return 1;
	} else {
		return 0;
	}
}

###########

sub _hash_password ($p) {
	my $cost = sprintf('%02d', _BCRYPT_COST || 6);
	my $settings = join( '$', '$2a', $cost, _bcrypt_salt() );
	return bcrypt($p, $settings);
}

sub _bcrypt_salt {
	my $num = 999999;
	my $cr = crypt( rand($num), rand($num) ) . crypt( rand($num), rand($num) );
	en_base64(substr( $cr, 4, 16 ));
}



1;
