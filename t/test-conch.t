use strict;
use warnings;
use v5.26;

use Test::More;
use Test::Conch;

subtest 'multiple Test::Conches talking to the same db' => sub {

	my $t = Test::Conch->new;
	my $new_user = $t->schema->resultset('UserAccount')->create({
		name => 'foo',
		email => 'foo@conch.joyent.us',
		password => $t->app->random_string,
	});

	my $t2 = Test::Conch->new(pg => $t->pg);
	my $new_user_copy = $t2->schema->resultset('UserAccount')->find({ name => 'foo' });
	is($new_user->id, $new_user_copy->id, 'can obtain the user from the second test instance');

};


done_testing;
