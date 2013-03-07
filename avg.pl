#!/usr/bin/perl

use 5.014;

use List::Util qw/sum/;

my $n_test = 3;           # number of test programs
my $n_imp = 4;            # number of implements (that is git-branchs)
my $n_avg_cnt = 5;        # run $n benchmarks

my @xls = ();
my @scores = ();
my @imps = ();

for (0..$n_test-1) {
    chomp(my $test = <>);
    push @xls, $test;
    for (0..$n_imp-1) {
        chomp(my $implement = <>);
        push @imps, $implement;
        my @score = ();
        for (0 .. $n_avg_cnt-1) {
            $score[$_] = <>;
        }
        push @scores, sprintf("%.5f",
#            log10(10*(($score[0] + $score[1] + $score[2]) / $n_avg_cnt)));
            (sum(@score) / $n_avg_cnt));
    }
}

$, = ',';
unshift @xls, " ";
say @xls;
for my $i (0 .. $n_imp-1) {
   print $imps[$i] . ", ";
    for my $j (0 .. $n_test-1) {
        print $scores[$i + $j*$n_imp] . ", ";
    }
    say;
}

sub log10 {
   my $n = shift;
   return log($n)/log(10);
}
