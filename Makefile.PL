package Apache::Dispatch;

use ExtUtils::MakeMaker;

require 5.005;

eval {
  require Apache::ExtUtils;
  require Apache::src;
};

my %makefile_params=(    
    'NAME'         => __PACKAGE__,
    'VERSION_FROM' => 'Dispatch.pm',
    );

    

if ($@ || $ENV{DISPATCH_PUREPERL}) {
    print "\nBuilding without Custom Apache Directives, use 'PerlSetVar' for configuration.\n\n";

    $makefile_params{'PL_FILES'}={'set_pureperl.PL'=>'1'}; 
    $makefile_params{'C'}=[]; 
    
} else {
    print "\nBuilding with Custom Apache Directives ('DispatchPrefix'). You 
will need a C compiler and Apache/mod_perl sources.\n\n";
    
    import Apache::ExtUtils qw(command_table);

   
    my @directives = (
  #------------------------------------------------------------------
  # DispatchPrefix defines the base class for a given <Location>
  #------------------------------------------------------------------
  { name         => 'DispatchPrefix',
    errmsg       => 'a class to be used as the base class', 
    args_how     => 'TAKE1',
    req_override => 'OR_ALL', },

  #------------------------------------------------------------------
  # DispatchExtras defines the extra dispatch methods to enable
  #------------------------------------------------------------------
  { name         => 'DispatchExtras',
    errmsg       => 'choose any of: Pre, Post, or Error', 
    args_how     => 'ITERATE',
    req_override => 'OR_ALL', },

  #------------------------------------------------------------------
  # DispatchStat enables module testing and subsequent reloading
  #------------------------------------------------------------------
  { name         => 'DispatchStat',
    errmsg       => 'choose one of On, Off, or ISA',
    args_how     => 'TAKE1',
    req_override => 'OR_ALL', },

  #------------------------------------------------------------------
  # DispatchAUTOLOAD defines AutoLoader behavior
  #------------------------------------------------------------------
  { name         => 'DispatchAUTOLOAD',
    errmsg       => 'choose one of On or Off',
    args_how     => 'FLAG',
    req_override => 'OR_ALL', },

  #------------------------------------------------------------------
  # DispatchDebug defines debugging verbosity
  #------------------------------------------------------------------
  { name         => 'DispatchDebug',
    errmsg       => 'numeric verbosity level',
    args_how     => 'TAKE1',
    req_override => 'OR_ALL', },

  #------------------------------------------------------------------
  # DispatchISA is a list of modules your module should inherit from
  #------------------------------------------------------------------
  { name         => 'DispatchISA',
    errmsg       => 'a list of parent modules',
    args_how     => 'ITERATE',
    req_override => 'OR_ALL', },

  #------------------------------------------------------------------
  # DispatchLocation allows you to redefine the <Location>
  #------------------------------------------------------------------
  { name         => 'DispatchLocation',
    errmsg       => 'a location to replace the current <Location>',
    args_how     => 'TAKE1',
    req_override => 'OR_ALL', },

  #------------------------------------------------------------------
  # DispatchRequire require()s the class
  #------------------------------------------------------------------
  { name         => 'DispatchRequire',
    errmsg       => 'choose one of On or Off',
    args_how     => 'FLAG',
    req_override => 'OR_ALL', },

  #------------------------------------------------------------------
  # DispatchFilter makes the dispatched handler Apache::Filter aware
  #------------------------------------------------------------------
  { name         => 'DispatchFilter',
    errmsg       => 'choose one of On or Off',
    args_how     => 'FLAG',
    req_override => 'OR_ALL', },

  #------------------------------------------------------------------
  # DispatchUppercase converts the first char of a class to uppercase
  #------------------------------------------------------------------
  { name         => 'DispatchUpperCase',
    errmsg       => 'choose one of On or Off',
    args_how     => 'FLAG',
    req_override => 'OR_ALL', },


    );

    command_table(\@directives);

    $makefile_params{'PL_FILES'}={'set_pureperl.PL'=>'0'}; 
   
    $makefile_params{'INC'}=Apache::src->new->inc;
    $makefile_params{'PREREQ_PM'}={ mod_perl => 1.2401, };
    $makefile_params{'clean'}={ FILES => '*.xs*' };
}

WriteMakefile(%makefile_params);

__END__

open (FH,catfile(qw(blib lib Apache Dispatch.pm))) || die "cannot read Dispatch.pm: $!";
my $code=join('',<FH>);
close FH;

$code=~s/%%PUREPERL%%/$pureperl/;

open (OUT,">".catfile(qw(blib lib Apache Dispatch.pm))) || die "cannot write to Dispatch.pm: $!";
print OUT $code;
close OUT;


