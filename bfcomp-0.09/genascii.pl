#!/usr/bin/perl

my $x = 0;
my $c = 0;

print "\tvar char = 0;";

$_ = $ARGV[0];

s/\\e/\e/g;
s/\\n/\n/g;
s/\\\\/\\/g;

while ( s/^(.)// ) {
	my $o = ord($1);
	print $c ? " " : "\n\t";
	print $o < $x ? "char -=" : "char +=";
	printf "%3d; out(char);", abs($x-$o);
	$x = $o; $c = ($c+1) % 3;
}

print "\n";

