use strict;
use warnings FATAL => 'all';

use Apache::Dispatch::TestConfig;
use Test::More;

plan skip_all => 'Apache::Test not configured'
  unless $Apache::Dispatch::TestConfig::HAS_APACHE_TEST;

plan skip_all => 'test library dependencies not met'
  unless eval { have_lwp() };

plan tests => 2;

my $url = '/oo/baz';

my $res = GET $url;
ok($res->is_success);
ok($res->content =~ m/dispatch_baz/i);
