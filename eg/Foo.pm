package Foo;

use Apache::Constants qw( OK SERVER_ERROR );
use strict;

sub dispatch_foo {
    my $class = shift;
    my $r = shift;
    $r->send_http_header('text/plain');
    $r->print("Foo->dispatch_foo()");
    print STDERR "Foo->dispatch_foo()\n";
    return OK;
}

sub dispatch_bar {
    print STDERR "Foo->dispatch_bar()\n";
    return SERVER_ERROR;
}

sub pre_dispatch {
    print STDERR "Foo->pre_dispatch()\n";
}

sub post_dispatch {
    print STDERR "Foo->post_dispatch()\n";
}

sub error_dispatch {
    my $class = shift;
    my $r = shift;
    $r->send_http_header('text/plain');
    $r->print("Yikes!  Foo->dispatch_error()");
    print STDERR "Yikes!  Foo->dispatch_error()\n";
    return OK;
}

sub dispatch_index {
    my $class = shift;
    my $r = shift;
    $r->send_http_header('text/plain');
    $r->print("Foo->dispatch_index()");
    print STDERR "Foo->dispatch_index()\n";
    return OK;
}

1;

__END__

here is a sample httpd.conf entry

  PerlModule Apache::Dispatch
  PerlModule Foo

  <Location /Test>
    SetHandler perl-script
    PerlHandler Apache::Dispatch
    DispatchPrefix Foo
    DispatchExtras Pre Post Error
  </Location>

once you install it, you should be able to go to
http://localhost/Test/foo
and get some results
