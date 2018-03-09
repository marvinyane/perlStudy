########################################################################################
# File: mipsElfParse.pl
# Author: Marvin yan
# Data: 2012-02-01
# Desc: 1. compiler xx.c 
#       2. link xx.o
#       3. readelf a.out > a.elf
#       4. parse a.elf (section bin & reloction).
#
#Argument: AGRV[0] a.elf
#          AGRV[1] a.bin
#File Format: 4 bits -> section number.
#             4 bits -> one of sections size, 4 bits -> size after compress.
#             x bits -> compress data.
#             ...
#             4 bits -> reloc infor size, 4 bits -> size after compress, 4 bits -> reloc section count.
#             x bits -> compress data.
#             4 bits -> MexApp_Start offset. 1 bits -> text section number.
#
#Reloc Format: header => 1 bits section NO., 2 bits reloc number. 
#              body => 2 bits -> offset, 1 bit -> type, 2 bits -> value, 1 bit -> section. 
#              ....
#
#
#
###########################################################################################
use warnings;
use Compress::Zlib;
# Global Variable {{{
my @allLines;  # input file lines.
my %sectionNumber;#sectionNumber{text} = 1; initialize in parseElfHeader
my %sectionSize; #sectionSize{text} = 0x12; initialize in parseElfHeader
my %sectionOff;  #sectionOff{text} = 0x34;  initialize in parseElfHeader
my $allocSectionNumber = 0;#                initialize in parseElfHeader
my %sectionName;  #sectionName{SYMBOL} = 1; initialize in parseSymtab
my $mexStartAddr; #                         initialize in parseStartFuncAddr
my $mexStartSection;
my @relocSectionArray;
my %relocSectionInfo; #relocSectionInfo{text} = 765;   in parseRelocInfo
my @relocInfo;        #relocInfo[0...4] = {offset,type,value,section} in parseRelocInfo
my %sectionNo;        #the section NO defined by myself, like ID
my %isSymFunc;
my %dumpSysFunc;
my $externSectionName = 'extern';
my $ctorsName = '.ctors';
#}}}
# check argument{{{

my $extra = 2;
if($#ARGV != $extra){
  die "wrong argument number.";
}
my $inputFile = $ARGV[0];
my $outputFile = $ARGV[1];
my $mapFile = $ARGV[2];

#}}}

open INPUTELF, "<$mapFile";
@allLines = <INPUTELF>;
close INPUTELF;

&prseExternArray();
&parseElfHeader();
&createBinFile();
&parseSymtab();
&parseRelocInfo();
&parseStartFuncAddr();
&addRelocInfo4Bin();
#&debug();
sub prseExternArray{ #{{{
  my $funcCount = 0;
  open FLOATFILE, "MexFloat.h" or die $!;
  while(<FLOATFILE>){
    if(/\(funcptr\)(\w+)/){
      $dumpSysFunc{$1} = $funcCount++;
    }
  }
  close FLOATFILE;
}# }}}
sub parseElfHeader{ # {{{
  my $isStart = 0;
  foreach(@allLines){
    if(/^Section Headers:$/){
      $isStart = 1;
      next;
    }
    if($isStart == 1){
      if(/^\s*\[\s?(\d+)\]\s*([\w\.]+)\s*\w+\s*[\da-fA-F]+\s*([\da-fA-F]+)\s*([\da-fA-F]+)\s+\d+\s+\w*A\w*/){
        $sectionNumber{$1} = $2;
        $sectionOff{$2} = hex($3);
        $sectionSize{$2} = hex($4);
        $allocSectionNumber++;
      }
    }
    if(/^Key to Flags:$/){
      last;
    }
  }
}
#}}}
sub createBinFile{ #{{{
  open LINK, "<$inputFile" or die $!;
  open BIN, ">$outputFile" or die $!;

  binmode LINK;
  binmode BIN;

  # 4 bits, section Number.
  if ($allocSectionNumber > 10){
	close BIN;
	unlink $outputFile;
	die "too many sections.";
  }
  print BIN pack("i",$allocSectionNumber);
  my $sectionNoCount = 0;
  foreach(sort{$sectionOff{$a} <=> $sectionOff{$b}} keys %sectionOff){
    my $outData;
    seek LINK, $sectionOff{$_}, 0;
    read(LINK, $outData, $sectionSize{$_});
    $sectionNo{$_} = $sectionNoCount++;
    if($_ eq ".bss"){
      print BIN pack("ii", $sectionSize{$_}, -1);
    }
    else{
      my $compressData = compress($outData, 9);
      print BIN pack("ii", $sectionSize{$_}, length($compressData));
      print BIN $compressData;
    }
  }
  $sectionNo{$externSectionName} = $sectionNoCount;
  close LINK;
  close BIN;
}
# }}}
sub parseSymtab{ # {{{{
  my %comSymbol;
  foreach(@allLines){
    if(/^.+(OBJECT|FUNC|NOTYPE)\s+\w+\s+\w+\s+(\[MIPS16\])?\s*(\d+|COM|UND|SCOM)\s+([\w\.\$]+)/){
      if($comSymbol{$4}++ > 0){
        #unlink $outputFile if (-e $outputFile);
        #die "symbol $4 multiple defined.\n";
      }
      if($3 eq 'UND'){
        if(exists $dumpSysFunc{$4}){
          $sectionName{$4} = $externSectionName;
        }
        else{
          unlink $outputFile if (-e $outputFile);
          die "undefined symbol $4\n";
        }
      }
      elsif($3 eq 'COM' || $3 eq 'SCOM'){
        unlink $outputFile if (-e $outputFile);
        die "$4 must be Explicit assignment.\n";
      }
      else{
        $sectionName{$4} = $sectionNumber{$3};
      }
      if($1 eq 'FUNC'){
        $isSymFunc{$4}++;
      }
    }
  }
}
# }}}}
sub parseRelocInfo{ # {{{
  my $testNo = 0;
  my $isStart = 0;
  my $testTotal = 0;
  my $baseAddr = 0;
  my $relocSectionCount = 0;
  %sectionNumber = reverse %sectionNumber;
  foreach(@allLines){
    if($isStart == 0){
      if(/^Relocation section '\.rel(\.\w+)' at offset 0[xX][\da-fA-F]+ contains (\d*) entries:/){
        unless(exists $sectionNo{$1}){
          next;
        }
        $relocSectionArray[$relocSectionCount++] = $1;
        $relocSectionInfo{$1} = $2;
        $testTotal = $2;
        $isStart = 1;
        $baseAddr = 0;
        $testNo = 0;
        next;
      }
    }
    if($isStart == 1){
      if(/^(\w+)\s+(\w+)\s+(\w+)\s+(\w+)\s+([\.\$\w]+)/){
        my $first = hex($1) - $baseAddr;
        $baseAddr = hex($1);
        my $second = &getRelType($3);
        my $third;
        if(exists $isSymFunc{$5} && $second == 0){
          $third = hex($4) + 1;
        }
        else{
          $third = hex($4);
        }
        my $forth;
        if(exists $sectionName{$5}){
          $forth = $sectionNo{$sectionName{$5}};
          # parse extern array.
          if(exists $dumpSysFunc{$5} && $sectionName{$5} eq $externSectionName){
            $third = $dumpSysFunc{$5};
          }
        }
        elsif(exists $sectionNumber{$5}){
          $forth = $sectionNo{$5};
        }
        else{
          unlink $outputFile if -e $outputFile;
          die "$5 is not exist."
        }
        push @relocInfo, $first, $second, $third, $forth;
      }
      if(++$testNo > $testTotal){
        $isStart = 0;
      }
    }
  }
}
# }}}
sub parseStartFuncAddr{ # {{{
  $isFound = 0;
  foreach(@allLines){
    if(/^\s+\d+\:\s+(\w+)(\s+\w+){4}\s+(\[MIPS16\])?\s*(\d+)\s+MexApp_Start$/){
      $mexStartAddr = hex($1);
      %sectionNumber = reverse %sectionNumber;
      $mexStartSection = $sectionNo{$sectionNumber{$4}};
      $isFound = 1;
      last;
    }
  }
  if($isFound == 0){
    unlink $outputFile if -e $outputFile;
    die "mex start functin 'MexApp_Start' not found";
  }
}
# }}}
sub getRelType{ # {{{
  my $relType = shift;
  if($relType eq "R_MIPS_32"){
    return 0;
  }
  elsif($relType eq "R_MIPS16_26"){
    return 1;
  }
  else{
    unlink $outputFile if -e $outputFile;
    die "not support relocation type.";
  }
}
#}}}
sub addRelocInfo4Bin{# {{{
  open BIN, ">>$outputFile" or die $!;
  binmode BIN;
  my $relocData = '';
  my $relocCount = 0;
  my $nowCount = 0;
  for(my $i = 0; $i <= $#relocSectionArray; $i++){
    $_ = $relocSectionArray[$i];
    my $rLen = length($relocData);
    $relocData = pack("a$rLen CS",$relocData, $sectionNo{$_},$relocSectionInfo{$_});
    for(my $i = $nowCount; $i < $relocSectionInfo{$_} + $nowCount; $i++){
      $rLen = length($relocData);
      $relocData = pack("a$rLen SCIC",$relocData,$relocInfo[$i*4],$relocInfo[$i*4+1],$relocInfo[$i*4+2],$relocInfo[$i*4+3]);
    }
    $nowCount += $relocSectionInfo{$_};
    $relocCount ++;
  }
  my $compressRelocData = compress($relocData, 9);
  print BIN pack("III", length($relocData), length($compressRelocData), $relocCount);
  print BIN $compressRelocData;
  # start funtion offset and text section number.
  print BIN pack("IC", $mexStartAddr, $mexStartSection);
  if(exists $sectionNo{$ctorsName}){
    print BIN pack("II", $sectionNo{$ctorsName}, $sectionSize{$ctorsName});
  }
  else{
    print BIN pack("II", -1, -1);
  }
  close BIN;
}
# }}}
sub debug{# {{{
  open DEBUG, ">debug.txt" or die $!;
  foreach(keys %relocSectionInfo){
    print DEBUG "$sectionNo{$_},$relocSectionInfo{$_}\n";
    for(my $i = 0; $i < $relocSectionInfo{$_}; $i++){
      print DEBUG "$relocInfo[$i*4] $relocInfo[$i*4+1] $relocInfo[$i*4+2] $relocInfo[$i*4+3]\n";
    }
  }
  close DEBUG;
}
# }}}
sub dumpSectionInfo{#{{{
  my $data = shift;
  open DUMP, ">dump.bin" or die $!;
  binmode DUMP;
  print DUMP $data;
  close DUMP;
}
# }}}
# vim: set fdm=marker:

