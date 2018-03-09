use warnings;

use Authen::SASL;
use Mail::Sendmail;

#$ENV{PATH} .= 'C:\\Program Files\\SlikSvn\\bin;' if not $ENV{PATH} =~ m/SlikSvn/;

@records = `ls -l`;

$content =join '', grep {not /.*\.pl/} @records;

print $content;

sendmail(
{
    To => 'yanjunzheng001@163.com',
    From => 'fcyjzh121@163.com',
    Message => $content,
}) or die $Mail::Sendmail::error;
