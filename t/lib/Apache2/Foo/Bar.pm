package Apache2::Foo::Bar;

use strict;
use warnings;

use Apache2::Const -compile => qw( OK SERVER_ERROR );
use Apache2::RequestRec;

@Foo::Bar::ISA = qw(Foo::Foo);

sub dispatch_baz {
    my ($class, $r) = @_;
    
	$r->log->debug("Foo->dispatch_baz()");
    $Foo::Foo::output = "pid $$";
    return Apache2::Const::OK;
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

  PerlLoadModule Apache2::Dispatch
  PerlModule Apache2::Foo::Bar

  <Location /Test>
    SetHandler perl-script
    PerlHandler Apache2::Dispatch
    DispatchPrefix Foo
    DispatchExtras Pre Post Error
  </Location>

once you install it, you should be able to go to
http://localhost/Test/Foo/foo
or
http://localhost/Test/Foo/Bar/foo
etc, and get some results
