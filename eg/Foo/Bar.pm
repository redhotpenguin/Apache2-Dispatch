package Foo::Bar;
use Apache::Constants qw( OK SERVER_ERROR );
use strict;

@Foo::Bar::ISA = qw(Foo::Foo);

sub dispatch_baz {
    my $r = Apache->request;
    print STDERR "Foo->dispatch_baz()\n";
    $Foo::Foo::output = "pid $$";
    return OK;
}

sub post_dispatch {
  my $self = shift;
  my $r = shift;
  # delay printing headers until all processing is done
  $r->send_http_header('text/plain');
  $r->print($Foo::Foo::output);
  print STDERR "Foo->post_dispatch()\n";
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
http://localhost/Test/Foo/foo
or
http://localhost/Test/Foo/Bar/foo
etc, and get some results
