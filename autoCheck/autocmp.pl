#! /usr/bin/perl

use warnings;
use XML::Simple;
use Data::Dumper;

use Storable qw(dclone);
use File::Basename qw<basename dirname>;

my $usage = "[Usage] : parseStruct module inputfile.
 such as :
	./parseStruct.pl req|cfm marvin_bt_gen_if.h...
";

if($#ARGV < 1){
	die $usage;
}

my $module = shift @ARGV;

if ($module ne 'req' && $module ne "cfm"){
	die $usage;
}

my $headfile = './data/marvin_hif.h';

my %struct;
my @macroInfo;
my $debugStr;
my %alias;
my %result;

&parseXml();
&parseMacro();
&parseAlias();

foreach my $input (@ARGV){
	if($module eq 'cfm'){
		unless($input =~ m/.*if.h/){
			die "$input is not cfm";
		}
	}
	&parseInputfile($input);
}

#&debug();
&parseOutputfile();

sub parseXml(){
	my $xml = XMLin("test.xml", ForceArray => 1);
	my @items = @{$xml->{'CmdList'}[0]->{'CMD'}};


	foreach (@items){
		my $group = $_->{'group'};
		my @params = @{$_->{'Param'}};
		my %names = %{$_->{'Name'}[0]};
		my $name = $names{'content'};
		my $type = $_->{'type'};
		
		if($module eq 'cfm' && $type eq 'CMD'){
			next;
		}

		if($module eq 'req' && $type eq 'EVT'){
			next;
		}

		my @values;

		foreach (@params){
			my @type = @{$_->{'Type'}};
			push @values, $type[0];
		}

		$result{$name} = \@values;
	}

	foreach (keys %result){
		my @params = @{$result{$_}};
	}
}

sub parseAlias(){
	open ALIAS, "<data/alias" or die "open alias failed";
	my $a_k;
	my $a_v;

	while(<ALIAS>){
		if(/^\s*$/){
			next;
		}

		if(defined $a_k){
			$a_v = $_;
			chomp($a_v);
			$alias{$a_k} = $a_v;
			undef $a_k;
		}
		else{
			$a_k = $_;
			chomp($a_k);
		}
	}

}

sub debug(){
	my @structWithnoMacro;
	$debugStr = "/*\n";
	foreach (@macroInfo){
		unless(exists $struct{$_}){
			unless(exists $alias{$_} && exists $struct{$alias{$_}}){
				$debugStr .= "\t$_ has no struct \n";
			}
		}
	}

	$debugStr .= "\n";
	foreach my $k (keys %struct){
		my $find  = 0;
		foreach(@macroInfo){
			if($_ eq $k){
				$find = 1;
				last;
			}
		}

		if($find eq 0){
			my %t_alias = reverse %alias;
			unless(exists $t_alias{$k}){
	 			$debugStr .= "\t${k}_T has no defined! \n";
	 			push @structWithnoMacro, $k;
			}

		}

		$find = 0;
	}

	$debugStr .= "*/\n";

	my $macroStart = 0xffff;
	foreach(@structWithnoMacro){
		$debugStr .= "#define $_ $macroStart \n";
		$macroStart--;
	}

}

sub parseMacro{
	open MACRO, "<$headfile" or die $!;
	my $rex = "define (BT_\\w+_(REQ|RES))\\s";

	if($module eq 'cfm'){
		$rex = "define (BT_\\w+_(CFM|IND))\\s";
	}
	while(<MACRO>){
		if(/$rex/i){
			push @macroInfo, $1;
		}
	}
}

sub getIsStruct{
	my $sname = shift;
	if(substr($sname, length($sname)-2, 2) eq '_T' && 
		substr($sname, 0, 3) eq 'BT_')
	{
		return 1;
	}

	return 0;
}

sub parseInputfile{
	my %tmpInfo;
	my $tmp_input = shift;
	open INPUT, "<$tmp_input";
	my $sign = 0;
	while(<INPUT>){
		if(/^\s*typedef (\w+?)_T\s+(\w+?)_T\s*;\s*$/){
			if(exists $struct{$1}){
				$struct{$2} = dclone($struct{$1});
			}
		}

		if($sign == 0){
			if(/^\s*typedef\s+struct\s*{?\s*$/){
				undef %tmpInfo;
				$sign = 1;
				next;
			}
		}
		elsif($sign == 1){
			if(/^\s*{\s*$/){
				next;
			}
			elsif(/^\s*}\s*(\w+)\s*;\s*$/){
				my $len = length($1);
				if(&getIsStruct($1) eq 1)
				{
					my $tmp1 = substr($1, 0, $len-2);
					$struct{$tmp1} = dclone(\%tmpInfo);
				}

				$sign = 0;
				next;
			}
			elsif(/^\s*}\s*(\w+)\s*,\s*$/){
				my $len = length($1);
				if(&getIsStruct($1) eq 1)
				{
					my $tmp1 = substr($1, 0, $len-2);
					$struct{$tmp1} = dclone(\%tmpInfo);
					$sign = 2;
				}
				else{
					$sign = 0;
				}
			}
			elsif(/^\s*}\s*$/){
				$sign = 2;
			}
			else{
				if(/^\s*(\w+)\s*\*\s*(\w+)\s*;\s*/){
					if($1 eq 'bdaddr'){
						$tmpInfo{$2} = 'bptr';
					}
					else{
						$tmpInfo{$2} = 'ptr';
					}
				}
				elsif(/^\s*(\w+)\s*\*?\s*(\w+)\[.*\]\s*;\s*/){
						$tmpInfo{$2} = 'ptr';
				}
				elsif(/^\s*(\w+)\s*(\w+)\s*;\s*/){
					$tmpInfo{$2} = $1;
				}
				elsif(/^\s*$/){
					next;
				}
				else{
					print "error! : $_\n";
				}
			}
		}
		elsif($sign == 2){
			if(/^\s*(\w+)\s*,\s*$/){
				my $len = length($1);
				if(&getIsStruct($1) eq 1)
				{
					my $tmp1 = substr($1, 0, $len-2);
					$struct{$tmp1} = dclone(\%tmpInfo);
				}
			}
			elsif(/^\s*(\w+)\s*;\s*$/){
				my $len = length($1);
				if(&getIsStruct($1) eq 1)
				{
					my $tmp1 = substr($1, 0, $len-2);
					$struct{$tmp1} = dclone(\%tmpInfo);
				}
				$sign = 0;
			}
			else{
				$sign = 0;
			}
		}
	}
}

sub parseOutputfile{
	foreach(@macroInfo){
		my $m_k;
		if(exists $struct{$_}){
			$m_k = $_;
		}
		elsif(exists $alias{$_} && exists $struct{$alias{$_}}){
			$m_k = $alias{$_};
		}

		if(defined $m_k && defined $result{$_}){
			my %value = %{$struct{$m_k}};
			my @params = @{$result{$_}};

			my $l_v = keys %value;
			my $l_p = $#params + 1;


			if($l_v ne $l_p){
			#	print "$_ $l_v $l_p \n";
			}


		}
		else{
			unless(defined $result{$_}){
				print "$_ \n";
			}
		}
	}
}