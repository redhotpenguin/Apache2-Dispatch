use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestRequest;

plan tests => 2, \&have_lwp;

my $url = '/extras/Bar/pre';

ok GET_OK   $url;

$url = '/extras/Bar/bad';

ok GET_OK   $url;
