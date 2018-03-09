#! /usr/bin/perl -w
use strict;

my %config = (
"MARVIN" => ['yjz', 'marvin', 'yanjunzheng'],
"ZHUDEWEN" => ['zdw', 'crpig', 'zhudewen'],
"ZHAOJIHUI-OPTIP" => ['zjh','zjh', 'zhaojihui'],
"LICHENG-UBUNTU" => ['lic','licheng', 'licheng'],
"DLFUTURE" => ['lhl','dlfuture', 'linhongliang'],
"LIUCHENWEI-PC2" => ['lcw','chellwee', 'liuchenwei'],
"hexiaolong-OptiPlex-990" => ['hxl', 'hexiaolong', 'hexiaolong'],
"anjie-HP-Compaq-8300-SFF" => ['anj', 'anjie', 'anjie'],
"BT-VOSTRO-3400" => ['bt', 'bt', 'bt']
);


my $ips = '';

foreach (keys %config)
{
    my $result = `nmblookup $_ -n`;

    my @line = split /\n/, $result;

    my @words = split /\s+/,$line[1];

    if ($words[0] eq 'name_query')
    {
        # print("$_ find fialed. \n");
    }
    else
    {
        $ips .= "Host $config{$_}[0]\n";
        $ips .= "HostName $words[0]\n";
        $ips .= "User $config{$_}[1]\n\n"
    }
}

foreach (keys %config)
{
    open CONFIG,  ">$config{$_}[2].config" or die $!;
    print CONFIG "
Host iauto
Hostname review.iauto.net
IdentityFile ~/.ssh/id_rsa
User $config{$_}[2]
Port 29418

Host igerrit.storm
Hostname igerrit.storm
IdentityFile ~/.ssh/id_rsa
User $config{$_}[2]\n\n";

print CONFIG $ips;
}
