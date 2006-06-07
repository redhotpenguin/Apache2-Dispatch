use strict;
use warnings FATAL => 'all';

use Apache::Test qw(-withtestmore);
use Apache::TestRequest;

# figure out what version we have - I don't like this method but it works
my $httpd   = Apache::Test::vars('httpd');
my $version = `$httpd -v`;

if ($version =~ m/Apache\/2/) {
    plan skip_all => "Filtering not yet implemented in Apache2::Dispatch";
}
else {
    plan tests => 2, \&need_lwp;
}

my $url = '/filtered/foo';

eval { require Apache::Filter };

my $res = GET $url;
ok($res->is_success);
ok($res->content =~ m/dispatchfoo/i);
