use warnings;

my $file = $ARGV[0];
my $aim = $ARGV[1];
my $time = 0;

open FILE, "<$file";
open AIM, ">$aim";
while(<FILE>){
    if(/\[(\d+)\:(\d+)\:(\d+)\.(\d+)\](AT[*|+].*)$/){
        my $now_time = ((($1 * 60 + $2) * 60) + $3) * 1000 + $4;
        if($time == 0){
            print AIM "$5 0\n";
        }
        else{
            my $sub_time = $now_time - $time;
            print AIM "$5 $sub_time\n";
        }
        $time = $now_time;
    }
}
close FILE;
close AIM;
