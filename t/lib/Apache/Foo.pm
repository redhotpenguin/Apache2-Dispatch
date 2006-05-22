package Apache::Foo;

use Apache::Constants qw( OK SERVER_ERROR );
use strict;

sub dispatch_foo {
    my $class = shift;
    my $r = shift;
    $r->log->debug(__PACKAGE__ . "->dispatch_foo()");
    
	$r->send_http_header('text/plain');
    $r->print(__PACKAGE__ . "->dispatch_foo()");
    return OK;
}

sub dispatch_uhoh {
    my ($class, $r) = @_;

	$r->log->debug(__PACKAGE__ . "->dispatch_bar()");
    return SERVER_ERROR;
}

sub pre_dispatch {
    my ($class, $r) = @_;
    $r->log->debug(__PACKAGE__ . "->pre_dispatch()");
}

sub post_dispatch {
    my ($class, $r) = @_;
    $r->log->debug(__PACKAGE__ . "->post_dispatch()");
	$r->print($Apache::Foo::output);
}

sub error_dispatch {
    my $class = shift;
    my $r = shift;
    $r->send_http_header('text/plain');
    $r->print("Yikes!  Foo->dispatch_error()");
    $r->log->error("Yikes!  " . __PACKAGE__ . "->dispatch_error()");
    return OK;
}

sub dispatch_index {
    my $class = shift;
    my $r = shift;
    $r->send_http_header('text/plain');
    $r->print(__PACKAGE__ . "->dispatch_index()");
    $r->log->debug(__PACKAGE__ . "->dispatch_index()");
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
