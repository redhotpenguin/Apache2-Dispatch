package Apache::Dispatch;

require 5.005;

use strict;

use lib 'lib';

use Apache::Dispatch::Util;
use ExtUtils::MakeMaker;

use constant HAS_APACHE_TEST => eval {
    require Apache::Test;
    require Apache::TestMM;

    Apache::TestMM->import(qw(test clean));
    Apache::TestMM::filter_args();

    my %args = @Apache::TestMM::Argv;

    die 'suitable httpd required'
      unless ( $args{apxs}
        or $args{httpd}
        or $ENV{APACHE_TEST_HTTPD}
        or $ENV{APACHE_TEST_APXS} );

    Apache::TestMM::generate_script('t/TEST');

    return Apache::TestMM->test;
};

warn $@ if $@;

sub MY::test {

    my $test = shift->MM::test(@_);

    eval { require Test::More } or return <<EOF;
test::
\t\@echo sorry, cannot run tests without Test::More
EOF

    return HAS_APACHE_TEST if HAS_APACHE_TEST;

    if ( eval { require Devel::Cover } ) {
        $test .= <<EOF;
testcover ::
	cover -delete
	HARNESS_PERL_SWITCHES=-MDevel::Cover make test
	cover
EOF
    }

    return $test;
}

sub MY::clean {

    if (HAS_APACHE_TEST) {
        require Apache::TestMM;

        return Apache::TestMM::clean(@_);
    }

    return shift->MM::clean(@_);
}

## which mp version ( 1.2x or 2.0.x)
my ( $mp_wanted, $mp_ver ) = &get_mp_ver();

print STDERR "Using mod_perl/$mp_ver\n\n";

my %prereq = ( 'Apache::Test' => "1.23" );

my %makefile_params = ( 'VERSION' => '0.10', );

if ( $mp_wanted == 2 ) {    # mod_perl2 specific makefile
    $prereq{'mod_perl2'} = 1.99023;    # this covers the naming change
    $makefile_params{'NAME'}      = 'Apache2::Dispatch';
    $makefile_params{'PREREQ_PM'} = \%prereq;

    WriteMakefile(%makefile_params);
}

elsif ( $mp_wanted != 2 ) {            # mod_perl1 specific makefile
    eval {
        require Apache::ExtUtils;
        require Apache::src;
    };

    # Build directives using xs or PerlSetVar
    my $pureperl;

    if ( $@ || $ENV{DISPATCH_PUREPERL} ) {
        print
"Building without Custom Apache Directives, use 'PerlSetVar' for configuration.\n\n";

        $makefile_params{'PL_FILES'} = { 'set_pureperl.PL' => '1' };
        $makefile_params{'C'}        = [];

    }
    else {
        print "Building with Custom Apache Directives ('DispatchPrefix'). You 
will need a C compiler and Apache/mod_perl sources.\n\n";

        $makefile_params{'PL_FILES'} = { 'set_pureperl.PL' => '0' };
        $makefile_params{'clean'}    = { FILES             => '*.xs*' };

        import Apache::ExtUtils qw(command_table);
        my @directives = Apache::Dispatch::Util->directives();
        command_table( \@directives );

        my $inc = Apache::src->new->inc;
        die "Can't find mod_perl header files installed" unless $inc;
        $makefile_params{'INC'} = $inc;
    }
    $makefile_params{'PREREQ_PM'} = { mod_perl => 1.2401 };
    WriteMakefile(
        NAME      => __PACKAGE__,
        PREREQ_PM => \%prereq,
        %makefile_params,
    );
}

# The next sub inspired by Apache::Peek 1.05

sub get_mp_ver {

    my $flag = 0;
    my @args = ();

    while ( my $arg = shift @ARGV ) {
        if ( $arg =~ /^MOD_PERL=([12])$/ ) {
            $flag = $1;
        }
        else {
            push @args, $arg;
        }
    }
    @ARGV = @args;

    # check %ENV
    my $env = exists $ENV{MOD_PERL} ? $ENV{MOD_PERL} : 0;

    # check for contradicting requirements
    if ( $env && $flag && $flag != $env ) {
        die <<EOF;
Can\'t decide which mod_perl version should be used, since you have
supplied contradicting requirements:
    enviroment variable MOD_PERL=$env
    Makefile.PL option  MOD_PERL=$flag
EOF
    }

    my $wanted = 2;    ## default to wanting mp2
    $wanted = 1 if $env == 1 || $flag == 1;

    my $mp_ver;

    if ( $wanted == 2 ) {
        eval { require mod_perl2 };
        my $req_ver = 1.999022;
        if ( $mod_perl2::VERSION < $req_ver || $@ ) {
            die
"mod_perl2 required version is $req_ver, you have $mod_perl2::VERSION.  Please upgrade to continue.";
        }
        else {
            $mp_ver = $mod_perl2::VERSION;
        }
    }
    else {
        eval { require mod_perl };
        no warnings qw(uninitialized);
        if ( $mod_perl::VERSION > 1.99 || $@ ) {
            die "You don't seem to have mod_perl 1.0 installed";
        }
        else {
            $mp_ver = $mod_perl::VERSION;
        }
    }

    return ( $wanted, $mp_ver );
}

