# vim: set ts=8 sts=4 sw=4 et :

requires 'perl', '5.26.0';


# basics
requires 'Data::UUID';
requires 'Data::Printer';
requires 'List::Compare';
requires 'Mail::Sendmail';
requires 'Try::Tiny';
requires 'Class::StrongSingleton';
requires 'Time::HiRes';
requires 'Time::Moment', '>= 0.43'; # for PR#28, fixes use of stdbool.h (thanks Dale)
requires 'Submodules';
requires 'JSON::Validator';
requires 'IO::All';
requires 'Pod::Github', '>= 0.04';

# mojolicious and networking
requires 'Mojolicious', '7.87'; # for Mojo::JSON's bootstrapping of Cpanel::JSON::XS
requires 'Cpanel::JSON::XS';
requires 'Mojo::Pg';
requires 'Mojo::Server::PSGI';
requires 'Mojo::JWT';
requires 'Mojolicious::Plugin::Bcrypt';
requires 'Mojolicious::Plugin::Util::RandomString';
requires 'Mojolicious::Plugin::NYTProf';
requires 'IO::Socket::SSL';

requires 'Moo';
requires 'Moo::Role::ToJSON';
requires 'Type::Tiny';
requires 'Types::Standard';
requires 'Types::UUID';
requires 'Role::Tiny';
requires 'List::MoreUtils';
requires 'List::MoreUtils::XS';
requires 'Getopt::Long::Descriptive';

### Legacy Deps
#
# String::CamelCase 0.03 had a broken META file that prevents the toolchain
# from being able to figure out its version, thus breaking 'carton install
# --deployment'. The issue was resolved in 0.04
# All our dependencies rely on 0.02 and up, but just to be careful, we'll pin
# it at 0.04 or greater.
requires 'String::CamelCase', '>= 0.04';

# database
requires 'DBD::Pg';
requires 'DBIx::Class';
requires 'DBIx::Class::Schema::Loader';
requires 'DBIx::Class::Helpers';
requires 'DateTime::Format::Pg';    # used by DBIx::Class::Storage::DBI::Pg
requires 'DBIx::Class::InflateColumn::TimeMoment';
requires 'Lingua::EN::Inflexion';

# logging
requires 'Log::Log4perl';
requires 'Log::Log4perl::Layout::JSON';
requires 'Log::Report';


on 'test' => sub {
    requires 'Test::More';
    requires 'Test::Exception';
    requires 'Test::PostgreSQL', ">= 1.24";
    requires 'Test::Pod::Coverage';
    requires 'YAML::XS';
    requires 'Test::Pod', '1.41';
    requires 'Test::Warnings';
    requires 'Test::Fatal';
    requires 'Test::Deep';
    requires 'Path::Tiny';
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
