[![Build Status](https://travis-ci.org/JaSei/Continual-Process.svg?branch=master)](https://travis-ci.org/JaSei/Continual-Process)
# NAME

Continual::Process - (re)start death process 

# SYNOPSIS

    use Continual::Process;
    use Continual::Process::Loop;
    
    my $loop = Continual::Process::Loop->new(
        instances => [
            Continual::Process->new(
                name => 'job1',
                code => sub {
                    my $pid = fork;
                    if ($pid) {
                        return $pid;
                    }
    
                    say "Hello world";
                    sleep 5;
                    say "Bye, bye world";
    
                    exit 1;
                },
                instances => 4,
            )->create_instance(),
            Continual::Process->new(
                name => 'job2',
                code => sub {
                    my $pid = fork;
                    if ($pid) {
                        return $pid;
                    }
    
                    exec 'perl -ne "sleep 1"';
    
                    exit 1;
                },
            )->create_instance(),
        ]
    );
    
    $loop->run();

# DESCRIPTION

Continual::Process with Continual::Process::Loop is way how running process forever.

Continual::Process creates Continual::Process::Instance which running in loop and if die, is start again.

Code for start process is OS-agnostic. The only condition is code must return PID of new process. 

## loop

Continual::Process support more loops:

- [Continual::Process::Loop::Simple](https://metacpan.org/pod/Continual::Process::Loop::Simple) - simple while/sleep loop
- [Continual::Process::Loop::AnyEvent](https://metacpan.org/pod/Continual::Process::Loop::AnyEvent) - [AnyEvent](https://metacpan.org/pod/AnyEvent) support
- [Continual::Process::Loop::Mojo](https://metacpan.org/pod/Continual::Process::Loop::Mojo) - [Mojo::IOLoop](https://metacpan.org/pod/Mojo::IOLoop) support

# METHODS

## new(%attributes)

### %attributes

#### name

name of process (only for identify)

#### code

CodeRef which start new process and returned `PID` of new process

_code_-sub **must** return `PID` of new process or die!

for example linux and fork:

    code => sub {
        if (my $pid  = fork) {
            return $pid;
        }

        ...

        exit 1;
    }

or windows and [Win32::Process](https://metacpan.org/pod/Win32::Process)

       code => sub {
           my ($instance) = @_;

                   Win32::Process::Create(
                           $ProcessObj,
                   "C:\\winnt\\system32\\notepad.exe",
                   "notepad temp.txt",
                   0,
                   NORMAL_PRIORITY_CLASS,
                   "."
           ) || die "Process ".$instance->name." start fail: ".$^E;
    
                   return $ProcessObj->GetProcessID();
       }

#### instances

count of running instances

default _1_

## create\_instance()

create and return list of [Continual::Process::Instance](https://metacpan.org/pod/Continual::Process::Instance)

# LICENSE

Copyright (C) Avast Software.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Jan Seidl <seidl@avast.com>
