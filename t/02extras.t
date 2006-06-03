use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;

plan tests => 5, \&have_lwp;

my $uri = '/extras';
my $res = GET $uri;
ok $res->code == 200;
ok $res->content =~ m/post_dispatch/;
ok $res->content =~ m/pre_dispatch/;

$uri = '/extras/bad';
$res = GET $uri;
ok $res->code == 200;
ok $res->content =~ m/Yikes(.*?)dispatch_error/i;

