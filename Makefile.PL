package Apache::Dispatch;

use ExtUtils::MakeMaker;
use Apache::ExtUtils qw(command_table);
use Apache::src ();
use strict;

require 5.005;

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
  # DispatchCache caches the URI->method translation (somewhat)
  #------------------------------------------------------------------
  { name         => 'DispatchCache',
    errmsg       => 'choose one of On or Off',
    args_how     => 'FLAG',
    req_override => 'OR_ALL', },
);

command_table(\@directives);

sub MY::test {
  if (eval "require Apache::TestMM") {
    Apache::TestMM::generate_script('t/TEST');
    Apache::TestMM->import(qw(test clean));
    return Apache::TestMM->test;
  }

  # The whitespace in front of @echo MUST be a single tab!
  return <<'EOF';
test::
	@echo This test suite requires Apache::Test
	@echo available from the mod_perl 2.0 sources
	@echo or the httpd-test distribution.
EOF
}

WriteMakefile(
  'NAME'         => __PACKAGE__,
  'VERSION_FROM' => 'Dispatch.pm',
  'INC'          => Apache::src->new->inc,
  'PREREQ_PM'    => { mod_perl => 1.2401, },
  'clean'        => { FILES => '*.xs*' },
);

