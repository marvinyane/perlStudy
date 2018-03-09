#! /usr/bin/perl

use warnings;
use Storable qw(dclone);
use File::Basename qw<basename dirname>;
use Template;

my $usage = "[Usage] : parseStruct module inputfile.
 such as :
	./parseStruct.pl req|cfm marvin_bt_gen_if.h...
";

if($#ARGV < 1){
	die $usage;
}

my $headfile = './data/marvin_hif.h';

my $output = "test.html";

my %struct;
my @macroInfo;
my $debugStr;
my %alias;

&parseMacro();
&parseAlias();

foreach my $input (@ARGV){
	&parseInputfile($input);
}

&parseOutputfile();

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

sub parseMacro{
	open MACRO, "<$headfile" or die $!;
	my $rex = "define (BT_\\w+_(REQ|RES|CFM|IND))\\s";

#	if($module eq 'cfm'){
#		$rex = "define (BT_\\w+_(CFM|IND))\\s";
#	}
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
					#print "error! : $_\n";
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
	my %items;
	foreach(sort @macroInfo){
		my $m_k;

		if(exists $struct{$_}){
			$m_k = $_;
		}
		elsif(exists $alias{$_} && exists $struct{$alias{$_}}){
			$m_k = $alias{$_};
		}

		if(defined $m_k){
			my %value = %{$struct{$m_k}};
			$items{$_} = \%value;
		}
		else{
			$items{$_} = 0;
		}
	}

	my $tt = Template->new({
	        INCLUDE_PATH => './template/',
	        INTERPOLATE  => 1,
	}) || die "$Template::ERROR\n";

	my $vars = {
      items => \%items,
	};

	open OUTPUT, ">$output" or die $!;

	my $templateFile = 'template.tt';
	my $outputContent;
	$tt->process($templateFile, $vars, $outputContent) || die $tt->error();
 
	print OUTPUT $outputContent;	

}