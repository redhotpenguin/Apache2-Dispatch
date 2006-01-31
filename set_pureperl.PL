use strict;
use File::Spec::Functions;

my $pureperl=shift(@ARGV);

my $dispatch=catfile(qw(blib lib Apache Dispatch.pm));

open (FH,$dispatch) || die "cannot read Dispatch.pm: $!";
my $code=join('',<FH>);
close FH;

chmod(0755,$dispatch);

$code=~s/'PUREPERL'/$pureperl/;

open (OUT,">$dispatch") || die "cannot write to Dispatch.pm: $!";
print OUT $code;
close OUT;



