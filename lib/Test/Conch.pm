package Test::Conch;

use v5.26;
BEGIN { $ENV{MOJO_LOG_LEVEL} ||= 'debug' }  # before Test::Mojo changes it
use Mojo::Base 'Test::Mojo', -signatures;

use Test::More ();
use Test::PostgreSQL;
BEGIN { $ENV{CONCH_BLOWFISH_COST} = 1 }  # make /login run in 0.1ms instead of 4s
use Conch::DB;
use Test::Conch::Fixtures;
use Path::Tiny;
use Test::Deep ();
use Module::Runtime 'require_module';
use Conch::DB::Util;
use Scalar::Util 'blessed';
use Mojo::URL;
use Scalar::Util 'weaken';
use List::Util 'any';
use Data::Dumper ();
use next::XS;

=pod

=head1 DESCRIPTION

Takes care of setting up a L<Test::Mojo> with the Conch application pre-configured.

Includes JSON validation ability.

    my $t = Test::Conch->new;
    $t->get_ok('/')->status_is(200)->json_schema_is('Whatever');

=head1 CONSTANTS

=cut

# see also the 'conch_user' fixture in Test::Conch::Fixtures
use constant CONCH_USER => 'conch';
use constant CONCH_EMAIL => 'conch@conch.joyent.us';
use constant CONCH_PASSWORD => '*';     # in the test fixture, all passwords are accepted

$ENV{EMAIL_SENDER_TRANSPORT} = 'Test';  # see Email::Sender::Manual::QuickStart

use constant API_VERSION_RE => qr/v\d+\.\d+(?:\.\d+)?(?:-[ab]\d+)?-\d+-g[[:xdigit:]]+/;

=head1 METHODS

=head2 pg

Override with your own L<Test::PostgreSQL> object if you want to use a custom database, perhaps
with extra settings or loaded with additional data.

This is the attribute to copy if you want multiple Test::Conch objects to be able to talk to
the same database.

=cut

has 'pg';   # Test::PostgreSQL object

=head2 fixtures

Provides access to the fixtures defined in L<Test::Conch::Fixtures>.
See L</load_fixture>.

=cut

has fixtures => sub ($self) {
    Test::Conch::Fixtures->new(
        schema => $self->app->schema,
        no_transactions => 1,   # we need to use multiple db connections at once
        # currently no hooks from Test::Conch::new for adding new definitions; see add_fixture.
    );
};

=head2 stash

After the request has been dispatched, contains the stash values.

=cut

has 'stash';

=head2 new

Constructor. Takes the following arguments:

  * pg (optional). uses this as the postgres db.
    Otherwise, an empty database is created, using the schema in sql/schema.sql.

  * config (optional). adds the provided configuration data.

=cut

sub new {
    my $class = shift;
    my $args = @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {};

    my $pg = exists $args->{pg} ? delete $args->{pg}
        : $args->{config}{features}{no_db} ? undef
        : $class->init_db // Test::More::BAIL_OUT('failed to create test database');

    my $self = Test::Mojo->new(
        Conch => {
            mode => $ENV{MOJO_MODE} // 'test',
            features => {
                no_db => ($pg ? 0 : 1),
                validate_all_requests => 1,
                validate_all_responses => 1,
                ($args->{config}//{})->{features} ? delete($args->{config}{features})->%* : (),
            },
            database => {
                $pg ? ( dsn => $pg->dsn, username => 'conch', ro_username => 'conch_read_only' )
                    : ( dsn => 'there is no database', username => '' )
            },
            mail => {
                from_host => 'joyent.com',
                ($args->{config}//{})->{mail} ? delete($args->{config}{mail})->%* : (),
            },
            logging => {
                max_history_size => 50,
                verbose => 1,
                do {
                  open my $access_log_fh, '>:raw', '/dev/null' or die "cannot open to /dev/null: $!";
                  access_log_handle => $access_log_fh,
                },
                ($args->{config}//{})->{logging} ? delete($args->{config}{logging})->%* : (),
            },

            secrets => ['********'],

            $args->{config} ? delete($args->{config})->%* : (),
        }
    );

    bless($self, $class);
    $self->pg($pg);
    $self->$_($args->{$_}) foreach keys $args->%*;

    # load all controllers, to find syntax errors sooner
    # (hypnotoad does this at startup, but in tests controllers only get loaded as needed)
    path('lib/Conch/Controller')->visit(
        sub ($file, $) {
            return if not -f $file;
            return if $file !~ /\.pm$/; # skip swap files
            my $module = 'Conch::Controller::'. ($file->basename =~ s/\.pm$//r);
            $self->app->log->info("loading $module");
            eval "require $module" or die $@;
        },
        { recurse => 1 },
    );

    weaken(my $t = $self);
    $self->app->plugins->on(mail_composed => sub ($, $email, @) {
        Test::More::note 'mail composed with Subject: '.$email->header('Subject');
        push $t->{_mail_composed}->@*, $email;
    });

    $t->app->hook(after_dispatch => sub ($c) { $t->stash($c->stash) });

    return $self;
}

sub DESTROY ($self) {
    # explicitly disconnect before terminating the server, to avoid exceptions like:
    # "DBI Exception: DBD::Pg::st DESTROY failed: FATAL:  terminating connection due to administrator command"
    if (not $self->app->feature('no_db')) {
        do { $_->disconnect if $_->connected }
            foreach $self->app->rw_schema->storage, $self->app->ro_schema->storage;
    }
}

=head2 init_db

Sets up the database for testing, using the final schema rather than running migrations.
No data is added -- you must load all desired fixtures.

Note that the L<Test::PostgreSQL> object must stay in scope for the duration of your tests.
Returns the L<Conch::DB> object as well when called in list context.

=cut

sub init_db ($class) {
    my $pgsql = Test::PostgreSQL->new;
    die $Test::PostgreSQL::errstr if not $pgsql;

    Test::More::note('connecting to ',$pgsql->dsn) if $ENV{DBIC_TRACE};
    my $schema = Conch::DB->connect(
        $pgsql->dsn, 'postgres', undef,
        {
            # same as from Mojo::Pg->new($uri)->options
            AutoCommit          => 1,
            AutoInactiveDestroy => 1,
            PrintError          => 0,
            PrintWarn           => 0,
            RaiseError          => 1,
        },
    );

    # ensure that $schema is always destroyed first
    $schema->{__conch_pgsql} = $pgsql;

    Test::More::note('initializing database with sql/schema.sql...');
    Conch::DB::Util::initialize_db($schema, 'create_role_and_db');

    return wantarray ? ($pgsql, $schema) : $pgsql;
}

=head2 ro_schema

Returns a read-only connection to an existing L<Test::PostgreSQL> instance (requires
L</init_db> to have been run first).

=cut

sub ro_schema ($class, $pgsql) {
    Test::More::note('connecting to ',$pgsql->dsn,' as user conch_read_only') if $ENV{DBIC_TRACE};
    Conch::DB->connect(
        $pgsql->dsn, 'conch_read_only', undef,
        +{
            # same as from Mojo::Pg->new($uri)->options
            AutoCommit          => 1,
            AutoInactiveDestroy => 1,
            PrintError          => 0,
            PrintWarn           => 0,
            RaiseError          => 1,
        },
    );
}

=head2 status_is

Wrapper around L<Test::Mojo/status_is>, adding some additional checks.

 0. GET requests should not have request body content
 1. successful GET requests should not return 201, 202 (ideally just 200, 204)
 2. successful DELETE requests should not return 201
 3. 201 and most 3xx responses should have a Location header
 3.1. 2xx and 4xx JSON responses should have a Link header
 4. HEAD requests should not have body content
 5. 200, 203, 206, 207 and most 4xx responses should have body content
 6. 204, 205 and most 3xx responses should not have body content
 7. 302 should not be used at all
 8. 401, 403 responses should have a WWW-Authenticate header

Also, unexpected responses will dump the response payload.

=cut

sub status_is ($self, $status, $desc = undef) {
    my $result = do {
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        $self->next::method($status, $desc);
    };

    my $method = $self->tx->req->method;
    my $code = $self->tx->res->code;

    # 0.
    $self->test('fail', 'GET requests should not have request body content')
        if $method eq 'GET' and $self->tx->req->text;

    # 1.
    $self->test('fail', $method.' requests should not return '.$code)
        if $method eq 'GET' and any { $code == $_ } 201,202;

    # 2.
    $self->test('fail', $method.' requests should not return '.$code)
        if $method eq 'DELETE' and $code == 201;

    # 3.
    $self->test('fail', $code.' responses should have a Location header')
        if any { $code == $_ } 201,301,302,303,305,307,308 and not $self->header_exists('Location');

    # 3.1.
    $self->test('fail', $code.' responses should have a Link header')
        if ($code >= 200 and $code < 300 or $code >= 400 and $code < 500)
            and $self->tx->res->json and not $self->tx->res->headers->link;

    # 4.
    $self->test('fail', 'HEAD requests should not have response body content')
        if $method eq 'HEAD' and $self->tx->res->text;

    # 5.
    $self->test('fail', $code.' responses should have content')
        if $method ne 'HEAD' and any { $code == $_ } 200,203,206,207,400,401,403,404,409,422 and not $self->tx->res->text;

    # 6.
    $self->test('fail', $code.' responses should not have content')
        if any { $code == $_ } 204,205,301,302,303,304,305,307,308 and $self->tx->res->text;

    # 7.
    $self->test('fail', 'HTTP 302 is superseded by 303 and 307')
        if $code == 302;

    # 8.
    $self->test('fail', 'HTTP 401 and 403 responses must have a WWW-Authenticate header')
        if ($code == 401 or $code == 403) and not $self->header_exists('WWW-Authenticate');

    Test::More::diag('got response: ', Data::Dumper->new([ $self->tx->res->json ])
            ->Sortkeys(1)->Indent(1)->Terse(1)->Maxdepth(5)->Dump)
        if $self->tx->res->code != $status;

    return $result;
}

=head2 location_is

Stolen from L<Test::Mojo>'s examples. I don't know why this isn't just part of the interface!

=cut

sub location_is ($self, $value, $desc = 'location header') {
    $value = Mojo::URL->new($value) if not blessed($value);
    return $self->test('is', $self->tx->res->headers->location, $value, $desc);
}

=head2 location_like

As L</location_is>, but takes a regular expression.

=cut

sub location_like ($self, $pattern, $desc = 'location header') {
    return $self->test('like', $self->tx->res->headers->location, $pattern, $desc);
}

=head2 json_schema_is

Validates the JSON response of the most recent request. If given a string that looks like a URL,
fetches that URL; otherwise if a string, looks up the schema in C<#/$defs> in the JSON Schema
response specification document to validate. If given a hash, uses the hash as the schema to
validate.

=cut

sub json_schema_is ($self, $schema, $message = undef) {
    return $self->test('fail', 'No request has been made') unless $self->tx;
    my $data = $self->tx->res->json;
    return $self->test('fail', 'No JSON in response') unless $data;

    my ($schema_name, $result, @errors);
    if (ref $schema) {
        1;
    }
    elsif ($schema =~ /^http/) {
        $schema_name = $schema;
    }
    # we may have already validated against this response schema in an around_action hook
    elsif (exists $self->stash->{response_validation_errors}
            and exists $self->stash->{response_validation_errors}{$schema}) {
        @errors = $self->stash->{response_validation_errors}{$schema}->@*;
        ($schema_name, $schema, $result) = ($schema, undef, !@errors);
    }
    else {
        ($schema_name, $schema) = ($schema, 'response.yaml#/$defs/'.$schema);
    }

    if ($schema_name) {
        my $re = $schema_name =~ /^http/ ? qr{<([^>]+)>;} : qr{/json_schema/response/(\w+)>;};
        my ($name_in_link) = ($self->tx->res->headers->link // '') =~ /$re/;
        $self->test('is', $name_in_link, $schema_name, 'schema name in Link header matches actual response schema') if $schema_name;
    }

    $schema_name //= '<inlined>';
    if (not defined $result) {
        $result = $self->app->json_schema_validator->evaluate($data, $schema);
        @errors = $self->app->normalize_evaluation_result($result);
    }

    return $self->test('ok', $result, $message // 'JSON response has no schema validation errors')
        ->or(sub ($self) {
            Test::More::diag(
                @errors.' error(s) occurred when validating '
                .$self->tx->req->method.' '.$self->tx->req->url->path
                .' with schema '.$schema_name
                .($schema_name eq 'Null' || $schema_name eq 'Error'
                    ? ' -- perhaps you forgot to do $c->stash(\'response_schema\', $real_schema_name) ?' : '')
                .":\n\t"
                .Data::Dumper->new([ \@errors ])->Sortkeys(1)->Indent(1)->Terse(1)->Dump);

            0;
        }
    );
}

=head2 json_cmp_deeply

Like L<Test::Mojo/json_is>, but uses L<Test::Deep/cmp_deeply> for the comparison instead of
L<Test::More/is_deep>. This allows for more flexibility in how we test various parts of the
data.

=cut

sub json_cmp_deeply {
    my $self = shift;
    my ($p, $data) = @_ > 1 ? (shift, shift) : ('', shift);
    my $desc = Test::Mojo::_desc(shift, qq{cmp_deeply match for JSON Pointer "$p"});
    return $self->test('Test::Deep::cmp_deeply', $self->tx->res->json($p), $data, $desc);
}

=head2 stash_cmp_deeply

Test the L</stash> with L<Test::Deep/cmp_deeply>, with optional JSON Pointer.

=cut

sub stash_cmp_deeply {
    my $self = shift;
    my ($p, $data) = @_ > 1 ? (shift, shift) : ('', shift);
    my $desc = Test::Mojo::_desc(shift, qq{cmp_deeply match for JSON Pointer "$p"});
    my $got = Mojo::JSON::Pointer->new($self->stash)->get($p);
    $self->test('Test::Deep::cmp_deeply', $got, $data, $desc);
    Test::More::diag('got stash: ', Data::Dumper->new([ $got ])->Sortkeys(1)->Terse(1)->Dump)
        if not $self->success;
    return $self;
}

=head2 load_validation_plans

Takes an array ref of structured hash refs and creates a validation plan (if it doesn't
exist, or updates an existing entry otherwise) and adds specified validation plans for each of
the structured hashes.

Each hash has the structure:

    {
        id          => optional, if existing row should be updated
        name        => 'Validation plan name',
        description => 'Validation plan description',
        validations => [
            'Conch::Validation::Foo',
            'Conch::Validation::Bar',
        ]
    }

If a validation plan by the same id or name already exists, all associations to
validations are dropped before the specified validations are added. This allows
modifying the membership of the validation plans.

Returns the list of validations plan objects.

=cut

sub load_validation_plans ($self, $plans) {
    my @plans;

    for my $plan_data ($plans->@*) {
        my $plan = $self->app->db_legacy_validation_plans->active->search({
                exists $plan_data->{id} ? ( $plan_data->%{id} ) : ( $plan_data->%{name} ),
            })->single;
        if ($plan) {
            if (exists $plan_data->{id} and exists $plan_data->{name}) {
                $plan->name($plan_data->{name});
                $plan->update if $plan->is_changed;
            }
        }
        else {
            $plan = $self->app->db_legacy_validation_plans->create({ $plan_data->%{qw(name description)} });
            $self->app->log->info('Created validation plan '.$plan->name);
        }

        $plan->delete_related('legacy_validation_plan_members');
        foreach my $module ($plan_data->{validations}->@*) {
            my $validation = $self->load_validation($module);
            $plan->add_to_legacy_validations($validation);
        }
        $self->app->log->info('Loaded validation plan '.$plan->name);
        push @plans, $self->app->db_ro_legacy_validation_plans->find($plan->id);
    }
    return @plans;
}

=head2 load_validation

Add data for a validator module to the database, if it does not already exist.

=cut

sub load_validation ($self, $module) {
    my $validation = $self->app->db_ro_legacy_validations->active->search({ module => $module })->single;
    return $validation if $validation;

    require_module($module);

    $validation = $self->app->db_legacy_validations->create({
        name => $module->name,
        version => $module->version,
        description => $module->description,
        module => $module,
    });
    return $self->app->db_ro_legacy_validations->find($validation->id);
}

=head2 load_fixture

Populate the database with one or more fixtures.
Returns the objects that were explicitly requested.

=cut

sub load_fixture ($self, @fixture_names) {
    $self->fixtures->load(@fixture_names);
}

=head2 reload_fixture

Loads the fixture again. Will die if it already exists (you should use L</load_fixture> unless
you are sure it has since been deleted).

=cut

sub reload_fixture ($self, @fixture_names) {
    delete $self->fixtures->_cache->@{@fixture_names};
    $self->fixtures->load(@fixture_names);
}

=head2 add_fixture

Add one or more fixture definition(s), and populate the database with it.

=cut

sub add_fixture ($self, %fixture_definitions) {
    $self->fixtures->add_definition(%fixture_definitions);
    $self->fixtures->load(keys %fixture_definitions);
}

=head2 load_fixture_set

Generates a set of fixtures by name and optional arguments, then loads them into the database.
See L<Test::Conch::Fixtures/generate_set> for available sets.

=cut

sub load_fixture_set ($self, $fixture_set_name, @args) {
    my @fixture_names = $self->fixtures->generate_set($fixture_set_name, @args);
    $self->fixtures->load(@fixture_names);
}

=head2 generate_fixtures

Generate fixture definition(s) using generic data, and any necessary dependencies, and populate
the database with them.

Not-nullable fields are filled in with sensible defaults, but all may be overridden.

Data may be nested to indicate proper relationships.

e.g.:

    $t->generate_fixtures(
        device => {
            device_location => { rack_unit_start => 2 },    # creates a rack_layout automatically
        },
        rack_layouts => [
            { rack_unit_start => 1 },
            { rack_unit_start => 2 },    # ..making this entry redundant with the above
            { rack_unit_start => 3 },
        ],
        device_location => { rack_unit_start => 3 },        # but this will work too
    );

or, to get all the defaults with no overrides:

    $t->generate_fixtures('device_location');

See L<Test::Conch::Fixtures/_generate_definition> for the list of recognized types.

=cut

sub generate_fixtures ($self, @specification) {
    state $unique_num = 1000;
    push @specification, undef if @specification % 2;
    my @fixture_names = $self->fixtures->generate_definitions($unique_num++, @specification);
    return if not @fixture_names;
    $self->fixtures->load(@fixture_names);
}

=head2 authenticate

Authenticates a user in the current test instance. Uses default (superuser) credentials if not
provided. Optionally will bail out of B<all> tests on failure.

By default this will also set 'user_id' in the session (stored in C<< $t->ua->cookie_jar >>,
accessed internally via C<< $c->session('user_id') >>), so a token is not needed on subsequent
requests.

=cut

sub authenticate ($self, %args) {
    $args{bailout} //= 1 if not $args{email};
    $args{email} //= CONCH_EMAIL;
    $args{password} //= CONCH_PASSWORD; # note that if a fixture is used, everything is accepted (for speed)
    $args{set_session} //= JSON::PP::true;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    $self->post_ok('/login', json => { %args{qw(email password set_session)} })
        ->status_is(200, $args{message} // 'logged in as '.$args{email})
            or $args{bailout} and Test::More::BAIL_OUT('Failed to log in as '.$args{email});

    return $self;
}

=head2 txn_local

Given a subref, execute the code inside a transaction that is rolled back at the end. Useful
for testing with mutated data that should not affect other tests. The subref is called as a
subtest and is invoked with the test object as well as any additional provided arguments.

=cut

sub txn_local ($self, $test_name, $subref, @args) {
    $self->app->schema->txn_begin;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    Test::More::subtest($test_name => $subref, $self, @args);

    $self->app->schema->txn_rollback;
}

=head2 email_cmp_deeply

Wrapper around L<Test::Deep/cmp_deeply> to test the email(s) that were "sent".
C<$got> should contain a hashref, or an arrayref of hashrefs, containing the headers and
content of the message(s), allowing you to test any portion of these that you like using
cmp_deeply constructs.

    $t->email_cmp_deeply([
        {
            To => '"Foo" <foo@conch.us>',
            From => '"Admin' <admin@conch.us>',
            Subject => 'About your new account',
            body => re(qr/^An account has been created for you.*Username:\s+foo.*Email:\s+foo@conch.us\s+Password:/ms),
        },
    ]);

A default 'From' header corresponding to the main test user is added as a default to your
C<$expected> message(s) if you don't provide one.

Remember: "Line endings in the body will normalized to CRLF." (see L<Email::Simple/create>)

=cut

sub email_cmp_deeply ($self, $expected, $test_name = 'email was sent correctly') {
    return $self->test('fail', 'an email was delivered')
        if not $self->{_mail_composed} or not $self->{_mail_composed}->@*;

    $self->test(
        'Test::Deep::cmp_deeply',
        [
            map +{
                To => $_->header('To'),
                From => $_->header('From'),
                Subject => $_->header('Subject'),
                body => $_->body,
            },
            $self->{_mail_composed}->@*
        ],
        Test::Deep::bag(
            map +{
                From => '"'.$self->CONCH_USER.'" <'.$self->CONCH_EMAIL.'>', # overridable default
                $_->%*,
            },
            ref $expected eq 'ARRAY' ? $expected->@* : $expected
        ),
        $test_name,
    );
    Test::More::diag('emails sent: ', Test::More::explain($self->{_mail_composed})) if not $self->success;
    return $self;
}

=head2 email_not_sent

Tests that B<no> email was sent as a result of the last request.

=cut

sub email_not_sent ($self) {
    $self->test(
        'ok',
        (!$self->{_mail_composed} || !$self->{_mail_composed}->@*),
        'no email was sent',
    );
    Test::More::diag('emails sent: ', Test::More::explain($self->{_mail_composed})) if not $self->success;
    return $self;
}

=head2 log_is

Searches the log lines emitted for the last request for one with the provided message,
which can be either an exact string or anything that L<Test::Deep> recognizes.

If you are expecting a list of message strings (sent at once to the logger), pass a listref
rather than a list.

A log line at any level matches, or you can use a more specific method that matches only
one specific log level:

=head2 log_debug_is

=head2 log_info_is

=head2 log_warn_is

=head2 log_error_is

=head2 log_fatal_is

=cut

sub log_is ($self, $expected_msg, $test_name = 'log line', $level = undef) {
    $self->test(
        'Test::Deep::cmp_deeply',
        $self->app->log->history,
        Test::Deep::superbagof([
            Test::Deep::ignore,             # time
            $level // Test::Deep::ignore,   # level
            ref $expected_msg eq 'ARRAY' ? $expected_msg->@* : $expected_msg, # content
        ]),
        $test_name,
    );
    Test::More::diag('got log: ',
            Data::Dumper->new([ $self->app->log->history ])->Sortkeys(1)->Terse(1)->Dump)
        if not $self->success;
    return $self;
}

sub log_debug_is ($s, $e, $n = 'debug log line') { @_ = ($s, $e, $n, 'debug'); goto \&log_is }
sub log_info_is  ($s, $e, $n = 'info log line') { @_ = ($s, $e, $n, 'info'); goto \&log_is }
sub log_warn_is  ($s, $e, $n = 'warn log line') { @_ = ($s, $e, $n, 'warn'); goto \&log_is }
sub log_error_is ($s, $e, $n = 'error log line') { @_ = ($s, $e, $n, 'error'); goto \&log_is }
sub log_fatal_is ($s, $e, $n = 'fatal log line') { @_ = ($s, $e, $n, 'fatal'); goto \&log_is }

=head2 log_like

Like L</log_like>, but uses a regular expression to express the expected log content.

A log line at any level matches, or you can use a more specific method that matches only
one specific log level:

=head2 log_debug_like

=head2 log_info_like

=head2 log_warn_like

=head2 log_error_like

=head2 log_fatal_like

=cut

sub log_like ($self, $expected_msg_re, $test_name = 'log line', $level = undef) {
    @_ = ($self,
        ref $expected_msg_re eq 'ARRAY'
          ? (map Test::Deep::re($_), $expected_msg_re->@*)
          : Test::Deep::re($expected_msg_re),
        $test_name, $level);

    goto \&log_is;
}

sub log_debug_like ($s, $e, $n = 'debug log line') { @_ = ($s, $e, $n, 'debug'); goto \&log_like }
sub log_info_like  ($s, $e, $n = 'info log line') { @_ = ($s, $e, $n, 'info'); goto \&log_like }
sub log_warn_like  ($s, $e, $n = 'warn log line') { @_ = ($s, $e, $n, 'warn'); goto \&log_like }
sub log_error_like ($s, $e, $n = 'error log line') { @_ = ($s, $e, $n, 'error'); goto \&log_like }
sub log_fatal_like ($s, $e, $n = 'fatal log line') { @_ = ($s, $e, $n, 'fatal'); goto \&log_like }

=head2 logs_are

Like L</log_is>, but tests for multiple messages at once.

=cut

sub logs_are ($self, $expected_msgs, $test_name = 'log lines', $level = undef) {
    $self->test(
        'Test::Deep::cmp_deeply',
        $self->app->log->history,
        Test::Deep::superbagof(
            map [
                Test::Deep::ignore,             # time
                $level // Test::Deep::ignore,   # level
                $_,                             # content
            ],
            $expected_msgs->@*,
        ),
        $test_name,
    );
    Test::More::diag('got log: ',
            Data::Dumper->new([ $self->app->log->history ])->Sortkeys(1)->Terse(1)->Dump)
        if not $self->success;
    return $self;
}

=head2 reset_log

Clears the log history. This does not normally need to be explicitly called, since it is
cleared before every request.

=cut

sub reset_log ($self) {
    $self->app->log->history->@* = ();
}

sub _request_ok ($self, @args) {
    undef $self->{_mail_composed};
    $self->reset_log;
    my $result = $self->next::method(@args);

    my $dump_log;
    my $log_history = $self->app->log->history;
    if (not $ENV{SKIP_LOG_FATAL_TEST} and any { $_->[1] eq 'fatal' } $log_history->@*) {
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        $self->test('fail', 'should not have gotten a fatal log message');
        $dump_log = 1;
    }

    Test::More::diag 'log history: ',
            Data::Dumper->new([ $log_history ])->Sortkeys(1)->Indent(1)->Terse(1)->Dump
        if $dump_log || $self->tx->res->code == 500 && $self->tx->req->url->path !~ qr{^/_die};

    return $result;
}

=head2 add_routes

Convenience method to add additional route(s) to the application, without breaking the routes
that are already in a specific order.

C<$routes> should be a L<Mojolicious::Routes> object that holds the route(s) to be added.

=cut

sub add_routes ($self, $routes) {
    my $r = $self->app->routes;
    my $catchall = $r->find('catchall')->remove;

    # we need the babycart because add_child mutates the underlying list
    $r->add_child($_) foreach @{[ $routes->children->@* ]};

    $r->add_child($catchall);
}

=head2 do_and_wait_for_event

Sets up a L<Mojo::Promise> to wait for a specific event name, then executes the first subref
provided. When the event is received B<and> the task subref has finished, the success subref is
invoked with the argument(s) sent to the event. If the timeout is reached, the failure subref
is called, or if left undefined a test failure is generated.

=cut

sub do_and_wait_for_event ($self, $emitter, $event_name, $task, $success, $fail = undef) {
    # resolved when event $event_name is received
    my $event_promise = Mojo::Promise->new->timeout(10);

    $emitter->once($event_name => sub ($, @args) {
        $event_promise->resolve(@args);
    });

    # resolved when $task returns
    my $task_promise = Mojo::Promise->new;

    my $all_promises = Mojo::Promise->all($event_promise, $task_promise)
        ->then(
            sub ($event_promise_result, $task_promise_result) {
                $success->($event_promise_result->@*)
            },
            $fail //
                sub { Test::More::fail('promises failed while waiting for/handling '.$event_name.": @_"); },
        )
        ->catch(sub { Test::More::fail("promise failed: @_") });

    # execute the task, which should trigger the event and then all tests in $success
    Test::More::subtest 'listening for '.$event_name.' event' => sub {
        $task->($self);
        $task_promise->resolve;
        $all_promises->wait;
    };

    return $self;
}

1;
__END__

=pod

=head1 LICENSING

Copyright Joyent, Inc.

This Source Code Form is subject to the terms of the Mozilla Public License,
v.2.0. If a copy of the MPL was not distributed with this file, You can obtain
one at L<https://www.mozilla.org/en-US/MPL/2.0/>.

=cut
# vim: set sts=2 sw=2 et :
