use strict;
use warnings FATAL => 'all';

use Apache::Dispatch::TestConfig;
use Test::More;

plan skip_all => 'Apache::Test not configured'
  unless $Apache::Dispatch::TestConfig::HAS_APACHE_TEST;

plan skip_all => 'test library dependencies not met'
  unless eval { have_lwp() };

# figure out what version we have - I don't like this method but it works
my $httpd   = Apache::Test::vars('httpd');
my $version = `$httpd -v`;

if ($version =~ m/Apache\/2/) {
    plan skip_all => "Filtering not yet implemented in Apache2::Dispatch";
}
else {
    plan tests => 2;
}

my $url = '/filtered/foo';

eval { require Apache::Filter };

my $res = GET $url;
ok($res->is_success);
ok($res->content =~ m/dispatchfoo/i);
