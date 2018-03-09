#! /usr/bin/perl -w
use strict;
#use AnyEvent;

my %config = (
"MARVIN" => ['yjz', 'marvin'],
"MARVIN-NOTE" => ['note', 'marvin'],
);

open HOST, ">host" or die $!;
open CONFIG, ">config" or die $!;

print CONFIG "
Host goni
Hostname 192.168.8.74
IdentityFile ~/.ssh/id_rsa
User yanjunzheng
Port 29418

Host iauto
Hostname review.iauto.net
IdentityFile ~/.ssh/id_rsa
User yanjunzheng
Port 29418

Host igerrit.storm
Hostname igerrit.storm
IdentityFile ~/.ssh/id_rsa
User yanjunzheng
";


my $section = 8;
if ($#ARGV == 0)
{
    $section = shift;
}

#if ($section > 254 or $sectionion < 0)
#{
#}

for(my $i = 1; $i < 255; $i++){
	my $pid = fork();
	if ($pid) {
#	    my $t = AnyEvent->timer( after => 2, cb => sub { kill 9, $pid; exit;} );
	}else{
	    my $now = `nmblookup -A 192.168.$section.$i`;
        &parseInfo($now);
        exit(0);
	}
}

sub parseInfo{
    my $now =  shift;
    my @line = split /\n/, $now;

    my @ip = split /\s+/,$line[0]; #$ip[$#ip]
    my @mac = split /\s+/, $line[$#line];

    my @names = grep !/^\s*$/, @line[1..$#line-1];

    foreach (@names){
        my @value = split /\s+/, trim($_);

        if($value[1] eq '<00>' and $value[3] ne '<GROUP>'){
            print HOST "$ip[$#ip] $mac[$#mac] $value[0] \n";
            # $result{$value[0]} = $ip[$#ip];
            &getResult($ip[$#ip], $value[0]);
        }
    }
}

sub getResult{
    my $ip = shift;
    my $name = shift;

    foreach (keys %config)
    {
        if ($name eq $_)
        {
            print CONFIG "\n";
            print CONFIG "Host $config{$_}[0]\n";
            print CONFIG "HostName $ip\n";
            print CONFIG "User $config{$_}[1]\n\n"
        }

    }
}

sub trim{
    my $s = shift; $s =~ s/^\s+|\s+$//g; return $s;
}
