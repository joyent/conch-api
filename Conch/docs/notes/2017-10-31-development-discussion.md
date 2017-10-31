# 2017-10-41
# Development Discussion with Sungo, Dale, and Lane

## Version control

The `master` git branch is is shippable code. This doesn't mean that the code
should be deployed at any given commit; rather, it's of quality and substance
it can be deployed.

All development work will take place on branches. Pull Requests (PR) on the `master`
branch will be made in Github.another engineer must review and approve the PR
before it is merged into `master`, except in situations when a reviewer is
not available and a fix is urgently needed.

Commits that are exclusively documentation changes are also allowed to be
pushed directly to `master`.


## Deployment

To make code deployments push-button automatic, a simple Ansible configuration
will be added to the project to run migrations and deploy new code to
production and future staging environments.

An automated system using buildbot to deploy development branches associated
with a PR should also be considered.


## Code formatting

We will continue to use `perltidy` and `prettier` (for ES6) for consistent code
formatting. The command `make format` will run both.


## Database interfaces

Lane voiced his complaints about the shortcomings he finds with DBIx::Class
(DBIC), namely the awkwardness of writing complicated or optimized queries
using DBIC interfaces.  Sungo explained the motivation for DBIC came from
developers in contracting roles who wanted to abstract away the type of
database used from their code. We are decidedly only using Postgres, so this
advantage does not apply to us.

It was proposed to write a wrapper around DBD::PG and write raw SQL with
placeholders, unless we find some other suitable alternative.


## Testing and Coverage

Testing needs be used significantly more. Modules that are currently
ill-factored for testing should be written to be testable. Testing should be
done at multiple levels. We use should [Ephemeral PG](ephemeralpg.com) and
[Test::PostgreSQL](https://metacpan.org/pod/Test::PostgreSQL) to test the SQL
and database user.

Also discussed was writing POD for all modules and coverage tools, both for
testing and documentation coverage.


## Private CPAN (DarkPAN)

Sungo suggested setting up an internal CPAN, to host our own modules and
external dependencies. External dependencies may need to be pinned or modified,
and it may help distribution of our software or others

## Programming languages


* Perl -- Works well enough for an API server, and excels for software that
  needs run on a wide variety of systems (such as the various agents and
  reporters). Nothing written in Perl now should be re-written. `IO::Async` and
  invoking GNU `parallel` could be used to improve responsiveness and
  throughput, respectively.

* Go -- Fits the niche of CLI tools particularly well, as we can easily
  release statically-linked, cross-platform binaries.

* Erlang/Elixir -- If (when) we need a highly-available, scalable, and
  fault-tolerant system, we should strongly consider Erlang or Elixir. A
  particularly strong use-case is the ingestion of all device reports, which
  could be split off from the Perl API server where it currently resides.
