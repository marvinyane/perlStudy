use Template;
# 建一个 TT 的对象
my $tt = Template->new({
        INCLUDE_PATH => './template/',
        INTERPOLATE  => 1,
        EVAL_PERL => 1,
}) || die "$Template::ERROR\n";
 
my $vars = {
};


 
# 使用
my $templateFile = 'test1.tt';
my $outputContent;
$tt->process($templateFile, $vars, $outputContent) || die $tt->error();
 
print $outputContent;