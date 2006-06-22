use strict;
use warnings FATAL => 'all';

use Apache::Test qw(-withtestmore);
use Apache::TestRequest;

plan tests => 2, \&need_lwp;

my $url = '/oo/baz';

my $res = GET $url;
ok($res->is_success);
ok($res->content =~ m/dispatch_baz/i);
