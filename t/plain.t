use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;

plan tests => 4, \&have_lwp;

# Test Apache2::Foo->dispatch_index
my $url = '/plain/';
ok GET_OK $url;

# Test Apache2::Foo->dispatch_foo
$url = '/plain/foo';
ok GET_OK $url;

# Test Apache2::Foo::Bar->dispatch_index
$url = '/plain/Bar/';
ok GET_OK $url;

# Test Apache2::Foo::Bar->dispatch_foo
$url = '/plain/Bar/baz';
ok GET_OK $url;

