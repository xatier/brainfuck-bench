#!/usr/bin/perl -w

use strict;

sub hanoi($$$$);

sub hanoi($$$$) {
	my ($from, $other, $to, $num) = @_;

	hanoi($from, $to, $other, $num-1) if $num;
	print "move_slice($from, $to);\n";
	hanoi($other, $from, $to, $num-1) if $num;
}

hanoi(0, 1, 2, 5);

