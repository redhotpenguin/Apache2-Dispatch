use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;

plan tests => 1, \&have_lwp;

my $url = '/filtered/Bar/good';

eval { require Apache::Filter };

ok GET_OK $url;

