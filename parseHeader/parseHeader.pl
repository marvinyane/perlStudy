#! /usr/bin/perl

use warnings;
use strict;

foreach my $file (@ARGV)
{
    open my $in, "<$file" or die $!;

    my $start = 0;
    my @lines = <$in>;
    my $i = 0;
    close $in;

    for ($i = 0; $i <= $#lines; $i++)
    {
        $_ = $lines[$i];
        if(/^\s*$/)
        {
            print "empty line $i\n";
            next;
        }

        if (/^\s*\/\*/)
        {
            print "start line $i\n";
            $start = 1;
            #next;
        }

        if(/^.*\*\//)
        {
            print "stop line $i\n";
            if($start == 1)
            {
                $i++;
                $start = 2;
            }
            last;
        }
        else
        {
            if ($start == 1)
            {
                next;
            }
            else
            {
                last;
            }
        }
    }

    if ($start != 2)
    {
        $i = 0;
    }

    open my $out, ">$file" or die $!;

    open my $copy, "<copyright" or die $!;

    while(<$copy>)
    {
        print $out $_;
    }

    close $copy;

    for(my $j = $i; $j <= $#lines; $j++)
    {
        print $out $lines[$j];
    }

    close $out;
}
