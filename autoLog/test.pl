#! /usr/bin/perl -w

use strict;
use Data::Dumper qw(Dumper);

open INPUT, "<$ARGV[0]" or die $!;

my %hash = map {$_->[1] => join ' ', @$_[2..$#$_]} map{[split]} grep{/^\[APP\]/} <>;

print Dumper(\%hash);

