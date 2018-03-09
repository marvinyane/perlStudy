#! /usr/bin/perl

use warnings;
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

my $output = "marvin_bt_app_${module}_log.c";

my %param = (
	"uint8" => "0x%.2X",
	"int8" => "0x%.2X",
	"uint16" => "0x%.4X",
	"int16" => "0x%.4X",
	"uint24" => "0x%.6X",
	"int24" => "0x%.6X",
	"uint32" => "0x%.8X",
	"int32" => "0x%.8X",
	"BOOL" => "%d",
	"bool" => "%d",
	"ptr" => "%p"
);

my %struct;
my @macroInfo;
my $debugStr;
my %alias;

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
&debug();
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
	open MACRO, "<$headfile";
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

	my $include_str = "";
	foreach(@ARGV){
		my $tmp_file = basename $_;
		$include_str .= "#include \"$tmp_file\"\n";
	}

	open OUTPUT, ">$output" or die $!;

	my $now = gmtime;
	print OUTPUT "
/************************************************************************
*						Hello Stranger									*
*	This file is auto-generated, but you can modify it by yourself.		*
*																		*
*	Because some macro have no structure, and some structure without 	*
*	macro, so, I think you should add some code by yourself, and some 	*
*	parameter print format such as poniter only with a value, if more 	*
*	information needed, DIY.											*
*																		*
*	Enjoy it.															*
*	Author : Marvin Yane												*
*	Data   : $now													*
************************************************************************/
$debugStr\n
#include <stdio.h>
#include <time.h>
#include \"marvin_common.h\"
$include_str

#define LOCAL_DEBUG(fmt, args...) marvin_bt_logcat(\"APP\",fmt, ##args )

void marvin_bt_app_${module}_debug(char* func, uint16 id, void* _msg)
{
	time_t t;
	time(&t);

	switch(id){
";

	foreach(@macroInfo){
		print OUTPUT "\tcase( $_ ): \n\t{\n";

		my $m_k;

		if(exists $struct{$_}){
			$m_k = $_;
		}
		elsif(exists $alias{$_} && exists $struct{$alias{$_}}){
			$m_k = $alias{$_};
		}

		if(defined $m_k){
			my $logstr = "";
			my $logpar = "";
			print OUTPUT "\t\t${m_k}_T *msg = _msg;\n";
			$logstr .= "$_ ";
			my %value = %{$struct{$m_k}};
			foreach(keys %value){
				if(!exists $param{$value{$_}}){
					if($value{$_} eq 'bdaddr'){
						$logstr .=  "$_=%.4X-%.2X-%.6X ";
						$logpar .=  ",msg->$_.nap,msg->$_.uap, msg->$_.lap";
					}
					elsif($value{$_} eq 'bptr'){
						$logstr .= "$_=%.4X-%.2X-%.6X ";
						$logpar .= ",msg->$_->nap,msg->$_->uap, msg->$_->lap";
					}
					else{
						print $value{$_};
					}

				}
				elsif($value{$_} eq 'ptr'){
					$logstr .= "$_=[%s] ";
					$logpar .= ",msg->$_,msg->$_";
				}
				else{
					$logstr .= "$_=$param{$value{$_}} ";
					$logpar .= ",msg->$_";
				}
			}
			print OUTPUT "\t\tLOCAL_DEBUG(\"$logstr\\n\" $logpar);\n"
		}
		else{
			print OUTPUT "\t\tLOCAL_DEBUG(\"$_\\n\");\n";
		}
		print OUTPUT "\t\tbreak;\n\t}\n";
	}


	print OUTPUT "
	default:{
		LOCAL_DEBUG(\"[Error] $module 0x%.4X opcode lost!! \\n\", id);
		break;
	}
	}
}
	";
}
