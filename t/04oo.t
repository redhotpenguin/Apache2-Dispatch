use strict;
use warnings FATAL => 'all';

use Apache::Test qw(ok plan :withtestmore );
use Apache::TestRequest qw(GET);

plan tests => 2, need_lwp;

my $url = '/oo/baz';

my $res = GET $url;
ok($res->is_success);
ok($res->content =~ m/dispatch_baz/i);
