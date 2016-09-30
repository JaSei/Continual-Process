use strict;
use warnings;

use Test::More;

BEGIN {
    plan( skip_all => 'this test is for windows only' ) if $^O ne 'MSWin32';
};

use Continual::Process;
use Continual::Process::Loop::Simple;
use Win32::Process;
use File::Temp;

$ENV{C_P_DEBUG} = 1;

my $tick = 2;
my $tmp = File::Temp->new();
my $loop = Continual::Process::Loop::Simple->new(
    instances => [
        Continual::Process->new(
            name => 'job1',
            code => sub {
                my ($instance) = @_;

                my $pid = fork;
                if ($pid) {
                    return $pid;
                }

                print $tmp $instance->id."\n";

                exit 1;
            },
            instances => 4,
        )->create_instance(),
        Continual::Process->new(
            name => 'job2',
            code => sub {
                my ($instance) = @_;

                my $instance_id = $instance->id;

                Win32::Process::Create(
                    $proc,
                    $^X,
                    qq{perl -e "open my \$file, '<<', $tmp; print \$file $instance_id; close \$file; sleep 10"}, 
                    0,
                    NORMAL_PRIORITY_CLASS,
                    "."
                ) || die "Process ".$instance->id."start fail $^E";

                return $proc->GetProcessID();
            },
        )->create_instance(),
    ],
    tick => sub { $tick-- }
);

$loop->run();

done_testing(1);

runs_check($tmp, { 
        'job2.1' => 1,
        'job1.1' => 2,
        'job1.2' => 2,
        'job1.3' => 2,
        'job1.4' => 2,
    });

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
