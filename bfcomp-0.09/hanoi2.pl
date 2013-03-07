#!/usr/bin/perl -w

use strict;

my ($from, $other, $to, $num, $state) = (0, 1, 2, 5, 1);
my @ctx_stack;

sub ctx_push() { push @ctx_stack, [ $from, $other, $to, $num, $state ]; }
sub ctx_pop() { ($from, $other, $to, $num, $state) = @{ pop @ctx_stack }; }

sub hanoi() {
	my $depth = 1;

	while ($depth) {
		while ($state < 4) {
			if ( $state == 1 && $num > 0 ) {
				ctx_push();
				($from, $other, $to, $num, $state) =
					($from, $to, $other, $num-1, 0);
				$depth++;
			}
			if ( $state == 2 ) {
				print "move_slice($from, $to);\n";
			}
			if ( $state == 3 && $num > 0 ) {
				ctx_push();
				($from, $other, $to, $num, $state) =
					($other, $from, $to, $num-1, 0);
				$depth++;
			}
			$state++;
		}
		if ( --$depth ) {
			ctx_pop();
			$state++;
		}
	}
}

hanoi();

