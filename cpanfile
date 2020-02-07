# vim: set ft=perl ts=8 sts=4 sw=4 et :

print "Installing dependencies for conch, using $^X at version $]\n";
print "PERL5LIB=$ENV{PERL5LIB}\n\n";

requires 'perl', '5.026';
die "Your perl is too old! Requires 5.026, but this is $]" if "$]" < '5.026';

# basics
requires 'Carton';
requires 'Cpanel::JSON::XS', '4.10';
requires 'List::MoreUtils::XS';         # make List::MoreUtils faster
requires 'Data::UUID';
requires 'List::Compare';
requires 'Try::Tiny';
requires 'Time::HiRes';
requires 'Time::Moment', '>= 0.43'; # for PR#28, fixes use of stdbool.h (thanks Dale)
requires 'Time::Local', '1.27';     # https://pandorafms.com/blog/2020-perl/
requires 'JSON::Validator', '3.20'; # https://github.com/mojolicious/json-validator/pull/182, /190
requires 'Data::Validate::IP';      # for json schema validation of 'ipv4', 'ipv6' types
requires 'HTTP::Tiny';
requires 'Safe::Isa';
requires 'Encode', '2.98';
requires 'IPC::System::Simple';
requires 'Dir::Self';
requires 'Carp';
requires 'Module::Runtime';
requires 'Email::Valid';
requires 'Email::Simple';
requires 'Email::Sender::Simple';
requires 'Email::Sender::Transport::SMTP';
requires 'Net::DNS';    # not used directly, but Email::Valid sometimes demands it
requires 'experimental', '0.020';

# mojolicious and networking
requires 'Mojolicious', '8.31';
requires 'Mojo::Pg';
requires 'Mojo::JWT';
requires 'Mojolicious::Plugin::Util::RandomString', '0.07'; # memory leak: https://rt.cpan.org/Ticket/Display.html?id=125981
requires 'Mozilla::CA'; # not used directly, but IO::Socket::SSL sometimes demands it
requires 'IO::Socket::SSL';

requires 'Path::Tiny';
requires 'Moo';
requires 'MooX::HandlesVia';
requires 'strictures', '2';
requires 'namespace::clean';
requires 'Types::Standard';
requires 'Type::Tiny::XS';  # faster Type::Tiny and Types::Standard
requires 'Role::Tiny';
requires 'Getopt::Long::Descriptive';
requires 'Session::Token';
requires 'Sys::Hostname';
requires 'Sub::Install';
requires 'WebService::Rollbar::Notifier';
requires 'Digest::SHA';
requires 'Digest::MD5';
requires 'Unicode::UTF8';       # used internally by some things to speed up utf8 operations, when available
requires 'PerlIO::utf8_strict'; # ""

# debugging aids
requires 'Data::Printer', '0.99_019', dist => 'GARU/Data-Printer-0.99_019.tar.gz';
requires 'Devel::Confess';

# misc scripts
requires 'Pod::Usage';
requires 'Pod::Markdown::Github';
requires 'Pod::Markdown', '3.200';
requires 'Getopt::Long';

# database and rendering
requires 'DBD::Pg';
requires 'DBIx::Class';
requires 'DBIx::Class::Schema::Loader';
requires 'DBIx::Class::Helpers';
requires 'DateTime::Format::Pg';    # used by DBIx::Class::Storage::DBI::Pg
requires 'DBIx::Class::InflateColumn::TimeMoment';
requires 'Lingua::EN::Inflexion';
requires 'Text::CSV_XS';
requires 'DBIx::Class::PassphraseColumn';
requires 'Authen::Passphrase::BlowfishCrypt';

on 'test' => sub {
    requires 'Test::More';
    requires 'Test::PostgreSQL', '1.27';
    requires 'Test::Pod::Coverage';
    requires 'YAML::XS', '0.81';    # http://blogs.perl.org/users/tinita/2020/01/making-yamlpm-yamlsyck-and-yamlxs-safer-by-default.html
    requires 'Test::Pod', '1.41';
    requires 'Test::Warnings';
    requires 'Test::Fatal';
    requires 'Test::Deep';
    requires 'Test::Deep::JSON';
    requires 'Test::Memory::Cycle';
    requires 'Module::CPANfile';
    requires 'DBIx::Class::EasyFixture', '0.13';    # Moo not Moose
    requires 'Moo';
    requires 'MooX::HandlesVia';
    requires 'Storable';
    requires 'Test::Deep::NumberTolerant';
    requires 'Test::Spelling';
};

# note: DBD::Pg will fail to install on macos 10.13.x because Apple is
# shipping a bad berkeley-db. To fix (do this in a subshell you will close
# afterward, so as to not pollute your environment):
# sudo port install db48    # you may have this already
# eval $(perl -Mlocal::lib='local/lib/perl5')
# cpanm --look DB_File
# (you're now in another subshell)
# edit config.in to add these two lines, replacing the existing INCLUDE and LIB lines:
#   INCLUDE	= /opt/local/include/db48
#   LIB	= /opt/local/lib/db48
# perl Makefile.PL; make install
# <close subshell>
# see also: https://rt.cpan.org/Public/Bug/Display.html?id=125238
# and https://rt.perl.org/Ticket/Display.html?id=133280
