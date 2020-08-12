# Development Process

## Introduction

The [Conch API](https://github.com/joyent/conch) is developed using Github.

Requests and bugs are tracked using [Github
Issues](https://github.com/joyent/conch/issues).

The `master` branch is protected and cannot be modified directly:

* All code changes must be submitted as a pull request
* Every pull request must be reviewed and approved by at least one
  other developer
* Every pull request must pass the full test suite, as executed
  automatically by buildbot
* Every pull request must be up to date with `master`, containing no merge
  conflicts
* Each PR must be assigned to a version milestone. Consult the release
  manager (currently [ether](https://github.com/karenetheridge)) to
  determine which version is most appropriate.

## Choosing Work

Choosing work is analagous to Kanban style development. We grab work out
of the Github issues and get it done. Sometimes high priority work comes
in and we shift focus to that. But in general, we work the backlog.

The build world is an odd duck in that we are also the customers of our
own work. [The Conch Shell](https://github.com/joyent/conch-shell) and
[Conch Web UI](https://github.com/joyent/conch-ui.git) are the main consumers
of the API and also owned by Build. Those projects each obviously have their
own customers and needs but the features and optimizations for the API can
largely be determined in-house.

## Release Process

* When it is time to release a new version of the API, the release manager
  creates a new branch in git, named like `release/v2.45`. A new tag is also
  created in git, named like `v2.45.0`, with a commit message containing the
  changelog. The changelog is typically autogenerated using the `misc/ghch`
  script in the repository.

* When the tag is pushed into Github, Buildbot executes a test run
  and, if successful, creates a new Github release. The text of that
  release is the changelog that was posted in the relevant tag.

* This new release is pushed into staging by a member of the Conch team using
  Ansible (see the private
  [buildops-infra](https://github.com/joyent/buildops-infra) Github repo).

* The release manager sends out an email or mattermost notification announcing
  the deployment and summarizing the changes.

* The code stays in staging for a two weeks, during which time automated testing
  is performed. The user base is encouraged to test as well.

* Any bug fixes are applied both to `master` and the `release/v2.45`
  branch. They are then tagged as a minor version like `v2.45.1` and
  redeployed into staging.

* After the two week period, staging is deployed to production. A go/no-go call
  is made, usually during a BuildOps staff meeting.

* If bugs are found in production, they are applied both to `master` and
  the `release/v2.45` branch, tagged as a minor version and redeployed
  into production. If applicable, these bug fixes are also applied to the
  staging branch (`release/v2.46` in this example) and redeployed into staging

Currently, deploys are scheduled for Monday afternoons (US/Eastern) and are
visible in the BuildOps Google Calendar.

In general, we prefer a two week deploy cadence. v2.45.0 goes into
staging on Monday and we begin accepting PRs for v2.46. Two weeks later,
v2.45 goes to production, v2.46 is deployed to staging, and we being to accept
PRs for v2.47.

## Summary

When written out like this, the development and release processes seem
complicated. In practice, however, it is pretty lightweight and has minimal
requirements for the developer. The release process requires more work out of
the release manager but, again, in practice the process is pretty lightweight,
particularly on a two week release cadence.


