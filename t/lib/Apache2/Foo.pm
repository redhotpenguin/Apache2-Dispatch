package Apache2::Foo;

use Apache2::Const -compile => qw( OK SERVER_ERROR );
use Apache2::RequestIO;
use strict;

sub dispatch_foo {
    my ($class, $r) = @_;
    
	$r->content_type('text/plain');
    $r->print("Foo->dispatch_foo()");
    $r->log->debug("Foo->dispatch_foo()");
    return Apache2::Const::OK;
}

sub dispatch_bar {
    my ($class, $r) = @_;
	require Data::Dumper;
	$r->log->debug("ARGV is " . Data::Dumper::Dumper(\@_));
    $r->log->debug( "Foo->dispatch_bar()");
    return Apache2::Const::SERVER_ERROR;
}

sub pre_dispatch {
    my ($class, $r) = @_;
    $r->log->debug("Foo->pre_dispatch()");
}

sub post_dispatch {
    my ($class, $r) = @_;
    $r->log->debug("Foo->post_dispatch()");
}

sub error_dispatch {
    my ($class, $r) = @_;
    
	$r->send_http_header('text/plain');
    $r->print("Yikes!  Foo->dispatch_error()");
    return Apache2::Const::OK;
}

sub dispatch_index {
    my ($class, $r) = @_;
    
	$r->content_type('text/plain');
    $r->print("Foo->dispatch_index()");
    $r->log->debug( "Foo->dispatch_index()");
    return Apache2::Const::OK;
}

1;

__END__

here is a sample httpd.conf entry

  PerlModule Apache2::Dispatch
  PerlModule Apache2::Foo

  <Location /Test>
    SetHandler perl-script
    PerlHandler Apache2::Dispatch
    DispatchPrefix Apache2::Foo
    DispatchExtras Pre Post Error
  </Location>

once you install it, you should be able to go to
http://localhost/Test/foo
and get some results
