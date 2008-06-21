package Apache::Dispatch;

use strict;
use warnings;

use Config;

BEGIN {
    my $AB_VER = 0.02;
    my $fail_msg = "Warning: prerequisite Apache::Bootstrap $AB_VER not found.";
    
    eval { require Apache::Bootstrap };
    die $fail_msg . "\n" if $@;

    die $fail_msg . " We have $Apache::Bootstrap::VERSION.\n"
        if $Apache::Bootstrap::VERSION < $AB_VER;
}

my %prereqs = ( );
my %mp2     = ( mod_perl2 => 1.99022 );
my %mp1     = ( mod_perl => 0 );

my $mp_gen;
if ( $ENV{MOD_PERL_2_BUILD} ) {
    push @ARGV, "-apxs $ENV{MP_APXS}";
    my $mp_gen = Apache::Bootstrap->satisfy_mp_generation(2);
}
else {
    $mp_gen = Apache::Bootstrap->satisfy_mp_generation();
}

%prereqs = ( $mp_gen == 1 ? %mp1 : %mp2 );

my $HAS_APACHE_TEST = Apache::Bootstrap->check_for_apache_test();

my %common_opts = (
    PREREQ_PM => \%prereqs,
    clean     => { FILES => 't/TEST, *.xs*'  },
);

if ( $mp_gen == 1 ) {

    # Build directives using xs or PerlSetVar
    my %makefile_params = ();

    eval {
        require Apache::ExtUtils;
        require Apache::src;
      };

    if ( $@ || $ENV{DISPATCH_PUREPERL} ) {
        print
"Building without Custom Apache Directives, use 'PerlSetVar' for configuration.\n\n";
        $makefile_params{'PL_FILES'} = { 'set_pureperl.PL' => '1' };
        $makefile_params{'C'} = [];

    }
    else {
        print "Building with Custom Apache Directives ('DispatchPrefix'). You 
will need a C compiler and Apache/mod_perl sources.\n\n";

        $makefile_params{'PL_FILES'} = { 'set_pureperl.PL' => '0' };

        import Apache::ExtUtils qw(command_table);
        use lib 'lib';
        require Apache::Dispatch::Util;
        my @directives = Apache::Dispatch::Util->directives();
        command_table( \@directives );

        my $inc = Apache::src->new->inc;
        die "Can't find mod_perl header files installed" unless $inc;
        $makefile_params{'INC'} = $inc;
    }

    require ExtUtils::MakeMaker;
    ExtUtils::MakeMaker::WriteMakefile(
        %common_opts,
        %makefile_params,
        VERSION_FROM  => "lib/Apache/Dispatch.pm",
        NAME          => "Apache::Dispatch",
        ABSTRACT_FROM => 'lib/Apache/Dispatch.pm',
    );

}
else {
    require ModPerl::MM;
    ModPerl::MM::WriteMakefile(
        %common_opts,
        VERSION_FROM  => "lib/Apache2/Dispatch.pm",
        NAME          => "Apache2::Dispatch",
        ABSTRACT_FROM => 'lib/Apache2/Dispatch.pm',
    );
}

if ( $ENV{MOD_PERL_2_BUILD} ) {
    pop @ARGV;
}

package MY;

sub postamble {
    my $self = shift;

    my $string = $self->SUPER::postamble;

    $string .= <<'EOF';
tag :
	svn copy https://apache-dispatch.svn.sourceforge.net/svnroot/apache-dispatch/trunk https://apache-dispatch.svn.sourceforge.net/svnroot/apache-dispatch/tags/$(VERSION_SYM)
	@echo update lib/Apache/Dispatch.pm VERSION now
EOF

    return $string;
}

sub test {
    my $self = shift;

    eval { require Test::More } or return <<EOF;
test::
\t\@echo sorry, cannot run tests without Test::More
EOF

    return $self->Apache::TestMM::test(@_) if $HAS_APACHE_TEST;

    return <<EOF
test::
\t\@echo
\t\@echo sorry, cannot run tests without a properly
\t\@echo configured Apache-Test environment
\t\@echo
EOF
}

sub clean {
    my $self = shift;

    return $self->Apache::TestMM::clean(@_) if $HAS_APACHE_TEST;

    return $self->SUPER::clean(@_);
}
