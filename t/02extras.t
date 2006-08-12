use strict;
use warnings FATAL => 'all';

use Apache::Test qw(ok plan :withtestmore );
use Apache::TestRequest qw(GET);

plan tests => 5, need_lwp;

my $uri = '/extras';
my $res = GET $uri;
ok $res->code == 200;
ok $res->content =~ m/post_dispatch/;
ok $res->content =~ m/pre_dispatch/;

$uri = '/extras/bad';
$res = GET $uri;
ok $res->code == 200;
ok $res->content =~ m/Yikes(.*?)dispatch_error/i;

