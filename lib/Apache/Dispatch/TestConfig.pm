package Apache::Dispatch::TestConfig;

use strict;
use warnings FATAL => 'all';

our $HAS_APACHE_TEST = eval {
    require Apache::Test;
    Apache::Test->import(qw(have_lwp));

    Apache::TestRequest->import(qw(GET_BODY_ASSERT));

    require Apache::TestUtil;
    Apache::TestUtil->import(qw(t_write_perl_script));

    require Apache::TestServer;
    return Apache::TestServer->new->{config}->{vars}->{httpd};
};

1;