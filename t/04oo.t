use strict;
use warnings FATAL => 'all';

use Apache::Test qw(:withtestmore );
use Apache::TestRequest qw(GET);
use Test::More;

plan tests => 2, need_lwp;

my $url = '/oo/baz';

my $res = GET $url;
ok($res->is_success);
like($res->content, qr/dispatch_baz/i, 'content like dispatch_baz');
