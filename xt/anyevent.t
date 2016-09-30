use strict;
use warnings;

use Test::More tests => 1;
use v5.12;
use Continual::Process;
use Continual::Process::Loop::AnyEvent;
use File::Temp;

$ENV{C_P_DEBUG} = 1;

my $tmp  = File::Temp->new();
my $loop = Continual::Process::Loop::AnyEvent->new(
    instances => [
        Continual::Process->new(
            name => 'job1',
            code => sub {
                my ($instance) = @_;

                my $pid = fork;
                if ($pid) {
                    return $pid;
                }

                print $tmp $instance->id . "\n";

                exit 1;
            },
            instances => 4,
          )->create_instance(),
        Continual::Process->new(
            name => 'job2',
            code => sub {
                my ($instance) = @_;

                my $pid = fork;
                if ($pid) {
                    return $pid;
                }

                print $tmp $instance->id . "\n";
                exec 'perl -ne "sleep 1"';

                exit 1;
            },
        )->create_instance(),
    ],
);

$loop->run();

my $cv = AnyEvent->condvar;
my $end_timer = AnyEvent->timer(
    after => 1,
    cb    => sub {$cv->send()}
);
$cv->recv();

sleep 1;

runs_check(
    $tmp,
    {
        'job2.1' => 1,
        'job1.1' => 2,
        'job1.2' => 2,
        'job1.3' => 2,
        'job1.4' => 2,
    }
);

sub runs_check {
    my ($tmp, $expected) = @_;

    close $tmp;

    open my $file, '<', $tmp;
    my @rows = <$file>;
    close $file;

    my %histo;
    foreach my $row (@rows) {
        chomp $row;
        $histo{$row}++;
    }

    is_deeply(\%histo, $expected, 'runs check');
}
