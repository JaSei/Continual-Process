package Continual::Process::Helper;
use strict;
use warnings;

use parent 'Exporter';

our @EXPORT_OK = qw(prepare_fork prepare_run);

BEGIN {
    if ($^O eq 'MSWin32') {
        ## no critic (ProhibitStringyEval)
        eval q{
            use Win32::Process qw(NORMAL_PRIORITY_CLASS);
        };

        die $@ if $@;
    }
    else {
        use constant NORMAL_PRIORITY_CLASS => 'fake';
    }
}

=head1 NAME

Continual::Process::Helper - fork/run helper functions

=head1 SYNOPSIS

    Continual::Process->new(
        name => 'test',
        code => prepare_fork(sub { say 'hello new process' }),
    );

    #or

    Continual::Process->new(
        name => 'test',
        code => prepare_run($^X, '-ne "sleep 1"),
    );

=head1 DESCRIPTION

This module contains helper functions for help generate fork/run CodeRef's

=head1 FUNCTIONS

=head2 prepare_fork($code_ref)

prepare and return correct fork CodeRef which returns PID

=cut
sub prepare_fork {
    my ($code_ref) = @_;

    return sub {
        my ($instance) = @_;

        my $pid = fork;
        if ($pid) {
            return $pid;
        }
        elsif ($pid == 0) {
            $code_ref->($instance);
            exit 1;
        }

        die 'Unable to fork!';
    }
}

=head2 prepare_run($executable, $args)

prepare and return correct (multiplatform) CodeRef which returns PID

for Windows use L<Win32::Process>, for other platform fork-exec pattern

=cut

sub prepare_run {
    my ($executable, $args) = @_;

    if ($^O eq 'MSWin32') {
        return _prepare_run_win($executable, $args);
    }

    return _prepare_run_other($executable, $args);
}

sub _prepare_run_win {
    my ($executable, $args) = @_;

    return sub {
        my ($instance) = @_;

        Win32::Process::Create(
            my $proc,
            $executable,
            $args,
            0,
            NORMAL_PRIORITY_CLASS,
            "."
        ) || die "Process ".$instance->id."start fail $^E";
    };
}

sub _prepare_run_other {
    my ($executable, $args) = @_;

    return prepare_fork(sub {
        exec {$executable} $args;
    });
}

=head1 LICENSE

Copyright (C) Avast Software.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Jan Seidl E<lt>seidl@avast.comE<gt>

=cut

1;
