use strict;
use warnings;

use Test::More;

BEGIN {
    if (!eval { require AnyEvent; AnyEvent->import; 1 }) {
        plan skip_all => "AnyEvent is required for this test";
    }
}

use Continual::Process;
use Continual::Process::Loop::AnyEvent;
use Continual::Process::Helper qw(prepare_fork);
use File::Temp;

$ENV{C_P_DEBUG} = 1;

my $tmp  = File::Temp->new();
my $tick = 1;
my $cv = AnyEvent->condvar;
my $loop = Continual::Process::Loop::AnyEvent->new(
    instances => [
        Continual::Process->new(
            name => 'job1',
            code => prepare_fork(sub {
                my ($instance) = @_;

                print $tmp $instance->id . "\n";
            }),
            instances => 4,
          )->create_instance(),
        Continual::Process->new(
            name => 'job2',
            code => prepare_fork(sub {
                my ($instance) = @_;

                print $tmp $instance->id . "\n";
                exec {$^X} '-ne "sleep 1"';
            }),
        )->create_instance(),
    ],
    on_interval => sub {
        if (!$tick--) {
            $cv->send();
        }
    }
);

$loop->run();

my $end_timer = AnyEvent->timer(
    after => 0,
    cb    => sub {pass('AnyEvent async tick')}
);
$cv->recv();

sleep 4;

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

done_testing(2);

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
