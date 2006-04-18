package Apache::Dispatch::Util;

use strict;
use warnings;

=head1 NAME

  Apache::Dispatch::Util - methods for Apache::Dispatch and Apache2::Dispatch

=head1 DESCRIPTION

This package provides methods common to Apache::Dispatch and Apache2::Dispatch.

=head1 VARIABLES

=over 4

=item B<@_directives>

Private lexical array which contains the directives for configuration.  Used
by the directives() method.

=back

=cut
  
my @directives = (

    #------------------------------------------------------------------
    # DispatchPrefix defines the base class for a given <Location>
    #------------------------------------------------------------------
    {
     name         => 'DispatchPrefix',
     errmsg       => 'a class to be used as the base class',
     args_how     => 'TAKE1',
     req_override => 'OR_ALL',
    },

    #------------------------------------------------------------------
    # DispatchExtras defines the extra dispatch methods to enable
    #------------------------------------------------------------------
    {
     name         => 'DispatchExtras',
     errmsg       => 'choose any of: Pre, Post, or Error',
     args_how     => 'ITERATE',
     req_override => 'OR_ALL',
    },

    #------------------------------------------------------------------
    # DispatchStat enables module testing and subsequent reloading
    #------------------------------------------------------------------
    {
     name         => 'DispatchStat',
     errmsg       => 'choose one of On, Off, or ISA',
     args_how     => 'TAKE1',
     req_override => 'OR_ALL',
    },

    #------------------------------------------------------------------
    # DispatchAUTOLOAD defines AutoLoader behavior
    #------------------------------------------------------------------
    {
     name         => 'DispatchAUTOLOAD',
     errmsg       => 'choose one of On or Off',
     args_how     => 'FLAG',
     req_override => 'OR_ALL',
    },

    #------------------------------------------------------------------
    # DispatchISA is a list of modules your module should inherit from
    #------------------------------------------------------------------
    {
     name         => 'DispatchISA',
     errmsg       => 'a list of parent modules',
     args_how     => 'ITERATE',
     req_override => 'OR_ALL',
    },

    #------------------------------------------------------------------
    # DispatchLocation allows you to redefine the <Location>
    #------------------------------------------------------------------
    {
     name         => 'DispatchLocation',
     errmsg       => 'a location to replace the current <Location>',
     args_how     => 'TAKE1',
     req_override => 'OR_ALL',
    },

    #------------------------------------------------------------------
    # DispatchRequire require()s the class
    #------------------------------------------------------------------
    {
     name         => 'DispatchRequire',
     errmsg       => 'choose one of On or Off',
     args_how     => 'FLAG',
     req_override => 'OR_ALL',
    },

    #------------------------------------------------------------------
    # DispatchFilter makes the dispatched handler Apache::Filter aware
    #------------------------------------------------------------------
    {
     name         => 'DispatchFilter',
     errmsg       => 'choose one of On or Off',
     args_how     => 'FLAG',
     req_override => 'OR_ALL',
    },

    #------------------------------------------------------------------
    # DispatchUppercase converts the first char of a class to uppercase
    #------------------------------------------------------------------
    {
     name         => 'DispatchUpperCase',
     errmsg       => 'choose one of On or Off',
     args_how     => 'FLAG',
     req_override => 'OR_ALL',
    },
);

=head1 METHODS

=over 4

=item C<directives>

Provides the configuration directives in an array or array reference

  $directives = Apache::Dispatch::Util->directives;
  @directives = Apache::Dispatch::Util->directives;

=over 4

=item class: C<Apache::Dispatch::Util> ( class )

The calling class

=item ret: C<$directives|@directives> ( ARRAY | ARRAY ref )

Returns the directives in an array or array reference depending on the context
in which it is called.

=back

=cut

sub directives {
	my $class = shift;
	return wantarray ? @directives : \@directives;
}

=pod

=back

=cut

1;
