use strict;
use warnings FATAL => 'all';

use Apache::Dispatch::TestConfig;
use Test::More;

plan skip_all => 'Apache::Test not configured'
  unless $Apache::Dispatch::TestConfig::HAS_APACHE_TEST;

plan skip_all => 'test library dependencies not met'
  unless eval { have_lwp() };

plan tests => 5;

my $uri = '/extras';
my $res = GET $uri;
ok $res->code == 200;
ok $res->content =~ m/post_dispatch/;
ok $res->content =~ m/pre_dispatch/;

$uri = '/extras/bad';
$res = GET $uri;
ok $res->code == 200;
ok $res->content =~ m/Yikes(.*?)dispatch_error/i;

