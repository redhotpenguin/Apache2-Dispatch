use strict;
use warnings FATAL => 'all';

use Apache::Dispatch::TestConfig;
use Test::More;

plan skip_all => 'Apache::Test not configured'
  unless $Apache::Dispatch::TestConfig::HAS_APACHE_TEST;

plan skip_all => 'test library dependencies not met'
  unless eval { have_lwp() };

plan tests => 4;

# Test Apache2::Foo->dispatch_index
my $uri = '/plain';
ok GET_OK $uri;

# Test Apache2::Foo->dispatch_foo
$uri = '/plain/foo';
ok GET_OK $uri;

# Test non-usage of Apache2::Foo::Bar->dispatch_index since
# Apache2::Foo->dispatch_bar does not exist
$uri = '/plain/bar';
my $res = GET $uri;
ok $res->code == 404;

# Test Apache2::Foo::Bar->dispatch_baz
$uri = '/plain/bar/baz';
ok GET_OK $uri;

