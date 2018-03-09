#! /usr/bin/perl
use warnings;
use strict;

open INPUT, "<$ARGV[0]" or die $!;

my @type=("Empty","Run Lvl","Boot","New Time","Old
    Time","Init","Login","Normal","Term","Account");
my $recs = "";

while (<INPUT>) 
{
    $recs .= $_
}

foreach (split(/(.{384})/s,$recs)) 
{
    next if length($_) == 0;
    my ($type,$pid,$line,$inittab,$user,$host,$t1,$t2,$t3,$t4,$t5) = $_
    =~/(.{4})(.{4})(.{32})(.{4})(.{32})(.{256})(.{4})(.{4})(.{4})(.{4})(.{4})/s;
    if (defined $line && $line =~ /\w/) 
    {
        $line =~ s/\x00+//g;
        $host =~ s/\x00+//g;
        $user =~ s/\x00+//g;
        printf("%s %-8s %-12s %10s %-45s \n",scalar(gmtime(unpack("I4",$t3))),$type[unpack("I4",$type)],$user,$line,$host)
    }
}

print"\n"
