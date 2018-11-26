package Conch::Controller::Schema;

use Mojo::Base 'Mojolicious::Controller', -signatures;

use Mojo::Util qw(camelize);

=pod

=head1 NAME

Conch::Controller::Schema

=head1 METHODS

=head2 get

Get the json-schema in JSON format.

=cut

sub get ($c) {
    my $type = $c->stash('request_or_response');
    my $name = camelize $c->stash('name');

    my $validator = $type eq 'response' ? $c->get_response_validator
        : $type eq 'request' ? $c->get_input_validator
        : undef;
    return $c->status(400, { error => 'Cannot find validator' }) if not $validator;

    my $schema = _extract_schema_definition($validator, $name);
    return $c->status(404) if not $schema;

    return $c->status(200, $schema);
}

=head2 _extract_schema_definition

Given a JSON::Validator object containing a schema definition, extract the requested portion
out of the "definitions" section, including any named references, and add some standard
headers.

TODO: this (plus addition of the header fields) could mostly be replaced with just:

    my $new_defs = $jv->bundle({
        schema => $jv->get('/definitions/'.$title),
        ref_key => 'definitions',
    });

..except circular refs are not handled there, and the definition renaming leaks local path info.

=cut

sub _extract_schema_definition ($validator, $schema_name) {
    my $top_schema = $validator->schema->get('/definitions/'.$schema_name);
    return if not $top_schema;

    my %refs;
    my %source;
    my $definitions;
    my @topics = ([{ schema => $top_schema }, my $target = {}]);
    my $cloner = sub ($from) {
        if (ref $from eq 'HASH' and my $tied = tied %$from) {
            # this is a hashref which quacks like { '$ref' => $target }
            my ($location, $path) = split /#/, $tied->fqn, 2;
            (my $name = $path) =~ s!^/definitions/!!;

            if (not $refs{$tied->fqn}++) {
                # TODO: use a heuristic to find a new name for the conflicting definition
                if ($name ne $schema_name and exists $source{$name}) {
                    die 'namespace collision: '.$tied->fqn.' but already have a /definitions/'.$name
                        .' from '.$source{$name}->fqn;
                }

                $source{$name} = $tied;
                push @topics, [$tied->schema, $definitions->{$name} = {}];
            }

            ++$refs{'/traversed_definitions/'.$name};
            tie my %ref, 'JSON::Validator::Ref', $tied->schema, '/definitions/'.$name;
            return \%ref;
        }

        my $to = ref $from eq 'ARRAY' ? [] : ref $from eq 'HASH' ? {} : $from;
        push @topics, [$from, $to] if ref $from;
        return $to;
    };

    while (@topics) {
        my ($from, $to) = @{shift @topics};
        if (ref $from eq 'ARRAY') {
            push @$to, $cloner->($_) foreach @$from;
        }
        elsif (ref $from eq 'HASH') {
            $to->{$_} = $cloner->($from->{$_}) foreach keys %$from;
        }
    }

    $target = $target->{schema};

    # cannot return a $ref at the top level (sibling keys disallowed) - inline the $ref.
    while (my $tied = tied %$target) {
        (my $name = $tied->fqn) =~ s!^/definitions/!!;
        $target = $definitions->{$name};
        delete $definitions->{$name} if $refs{'/traversed_definitions/'.$name} == 1;
    }

    return {
        title => $schema_name,
        '$schema' => $validator->get('/$schema') || 'http://json-schema.org/draft-07/schema#',
        '$id' => 'urn:'.$schema_name.'.schema.json',
        keys $definitions->%* ? ( definitions => $definitions ) : (),
        $target->%*,
    };
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

# vim: set ts=4 sts=4 sw=4 et :
