#!/usr/bin/perl -w
use strict;
use XML::Simple qw(XMLout);
use Data::Dumper qw(Dumper);
my @segments = grep {/Name:/} split /\d\.\d+\.\d+\.\d+.*$/m, join '', <>;
my @records;
foreach my $segment (@segments){
	my (%record_hash,@params);
	my @pair_refs = map {[split /:\s*$/m]} grep {!/^\s*$/m} split /(?=^.+:\s*$)/m,$segment;
	my @p_indexs = grep {$pair_refs[$_][0] =~ m/param \d+/} 0..$#pair_refs;
	print Dumper(\@p_indexs);
	if (@p_indexs){
		push @p_indexs,$#pair_refs;
		for (my $i = 0; $i < $#p_indexs; $i++){
			my %param_hash;
			for my $pair_ref (@pair_refs[$p_indexs[$i]+1..$p_indexs[$i+1]-1]){
				$param_hash{"\u\L$$pair_ref[0]"} = [trim($$pair_ref[1])];
			}
			push @params,\%param_hash;	# 存储每个参数的键值对表
		}
		@pair_refs = @pair_refs[0..$p_indexs[0]-1,-1];
	}
	for my $pair_ref (@pair_refs){
		$record_hash{$$pair_ref[0]} = [trim($$pair_ref[1])];
	}
	$record_hash{'Param'} = \@params if @params;
	push @records,\%record_hash;
}
for my $record_ref (@records){
	$$record_ref{'type'} = hex($$record_ref{'flag'}[0]) ? 'EVT' : 'CMD';
	delete $$record_ref{'flag'};
	$$record_ref{'group'} = $$record_ref{'gid'}[0];
	$$record_ref{'OPCode'} = [sprintf("0x%02x",hex($$record_ref{'gid'}[0]) << 8 | hex($$record_ref{'fid'}[0]))];
	delete $$record_ref{'gid'};
	delete $$record_ref{'fid'};
}

open my $output,'>',"output.xml" or die "Can't open output file.$!";
print {$output} XMLout({'CMD'=>\@records},RootName=>"CmdList");

sub trim{
	 my $s = shift; $s =~ s/^\s+|\s+$//g; return $s;
}