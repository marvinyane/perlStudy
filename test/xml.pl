use warnings

my @allLines;

my $extra = 0;
if($#ARGV != $extra){
    die "wrong arguments count.";
}

my $inputFile = $ARGV[0];

open INPUTFILE, "<$inputFile";
open OUTPUTFILE, ">result.txt";

@allLines = <INPUTFILE>;
close INPUTFILE;

my $profile = "NULL";
my $opcode = "NULL";
my $valueue = "0x0";
my $count = 0;
foreach(@allLines){

    if(/group="(\w+)"/){
        $profile = $1;
    }
    if(/Name alias="\w+">(\w+)/){
        $opcode = $1;
    }
    if(/<OPCode>0x([\da-fA-F]+)<\/OPCode>/){
        if(length($1) == 0){
            $value = "0x0000";
        }
        if(length($1) == 1){
            $value = "0x000$1";
        }
        if(length($1) == 2){
            $value = "0x00$1";
        }
        if(length($1) == 3){
            $value = "0x0$1";
        }
        if(length($1) == 4){
            $value = "0x$1";
        }

        print "$1 $value \n";
        
        print OUTPUTFILE "$profile $opcode $value\n";
        $count ++;
    }
}

print "total count is $count";
