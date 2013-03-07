#!/usr/bin/perl

use strict;

my $pos=0;
my $roof=0;
my %chars = ();

my @primes = ();

$| = 1;

$_=1;
(1 x $_) !~ /^(11+)\1+$/ && push @primes,$_ while $_++ < 300;

open(OUT, "| fold -75") || die $!;

sub add_sub_on_roof($$)
{
	# return "+" x $num;

	my @alternatives = ();
	my ($a, $n, $p, $d);
	my ($op, $num) = @_;
	my $max = $num-2 < 10 ? $num-2 : 10;

	return $op x $num if $num < 5;

	for $a (0 .. $max) {
		my @dividers = ();

		$alternatives[$a] = $op x $a;
		$n = $num - $a;

		foreach $p (@primes) {
			while ( $n != 1 && $n % $p == 0 ) {
				$n /= $p;
				if ( $#dividers >= 0 ) {
					$d = $dividers[$#dividers];
					if ( $d * $p < 10 ) {
						$p *= $d;
						pop @dividers;
					}
				}
				push @dividers, $p;
			}
		}

		push @dividers, $n if $n != 1;
		$n = pop @dividers;
		if ( not defined $n ) {
			print OUT "\n";
			print OUT "$num, $a\n";
			exit;
		}
		$alternatives[$a] .= ">" x ($#dividers+1);

		foreach $d (@dividers) { $alternatives[$a].=("+" x $d)."[<"; }
		$alternatives[$a] .= $op x $n;
		foreach $d (reverse @dividers) { $alternatives[$a] .= ">-]"; }
		$alternatives[$a] .= "<" x ($#dividers+1);
	}

	$n = 0;
	$p = length $alternatives[0];
	for $a (1 .. $max) {
		if ($p > length $alternatives[$a]) {
			$n = $a;
			$p = length $alternatives[$a];
		}
	}
	return $alternatives[$n];
}

sub goto_pos($)
{
	while ($pos < $_[0]) { print OUT ">"; $pos++; }
	while ($pos > $_[0]) { print OUT "<"; $pos--; }
}

sub print_text($)
{
	my ($ch, $i);
	foreach $ch (split //, $_[0]) {
		if ( defined $chars{ord($ch)} ) {
			goto_pos($chars{ord($ch)});
		} else {
			for my $o (1 .. 10) {
				if (defined $chars{ord($ch)-$o} ) {
					goto_pos($chars{ord($ch)-$o});
					delete $chars{ord($ch)-$o};
					$chars{ord($ch)} = $pos;
					print OUT "+" x $o;
					goto print_this_char;
				}
				if (defined $chars{ord($ch)+$o} ) {
					goto_pos($chars{ord($ch)+$o});
					delete $chars{ord($ch)+$o};
					$chars{ord($ch)} = $pos;
					print OUT "-" x $o;
					goto print_this_char;
				}
			}
			goto_pos($roof);
			print OUT add_sub_on_roof("+", ord($ch));
			$chars{ord($ch)} = $roof++;
		}
print_this_char:
		print OUT ".";
	}
}

print OUT "+++>"; # usless, but makes outmut a multiple of 75
print_text "++ Brainf*ck ++ http://www.clifford.at/bfcpu/ +";
print_text "+ CPU, Compiler, etc.. ++\n";

print OUT "\n";
close OUT;

