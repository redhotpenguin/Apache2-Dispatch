package Apache::Dispatch;

# $Id: Dispatch.pm,v 1.34 2002/12/02 19:29:26 geoff Exp $

#---------------------------------------------------------------------
#
# usage: PerlHandler Apache::Dispatch
#
#---------------------------------------------------------------------

use strict;
use warnings;

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
    # DispatchDebug defines debugging verbosity
    #------------------------------------------------------------------
    {
     name         => 'DispatchDebug',
     errmsg       => 'numeric verbosity level',
     args_how     => 'TAKE1',
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

use mod_perl 1.2401;
use Apache::Constants qw(OK DECLINED SERVER_ERROR);
use Apache::Log;

$Apache::Dispatch::PUREPERL = 'PUREPERL';    # set during perl Makefile.PL

# create global hash to hold the modification times of the modules
my %stat = ();

if ($Apache::Dispatch::PUREPERL == 0) {
    require Apache::ModuleConfig;
    require DynaLoader;
    @Apache::Dispatch::ISA = qw(DynaLoader);
    Apache::Dispatch->bootstrap($Apache::Dispatch::VERSION);
}

sub directives {
    return wantarray ? @directives : \@directives;
}

# set debug level
#  0 - messages at info or debug log levels
#  1 - verbose output at info or debug log levels
#  2 - really verbose output at info or debug log levels
#  this is rapidly becoming deprecated
$Apache::Dispatch::DEBUG = 0;

sub handler {

    #---------------------------------------------------------------------
    # initialize request object and variables
    #---------------------------------------------------------------------

    my $r = shift;

    my $dcfg;
    if ($Apache::Dispatch::PUREPERL == 0) {
        $dcfg = Apache::ModuleConfig->get($r, __PACKAGE__);
    }
    else {
        $dcfg = get_pureperl_config($r);
    }

    my $filter = $dcfg->{_filter}
      || $r->dir_config('Filter')
      || 0;

    my $debug =
      defined $dcfg->{_debug}
      ? $dcfg->{_debug}
      : $Apache::Dispatch::DEBUG;

    my $autoload = $dcfg->{_autoload};

    my $stat = $dcfg->{_stat};

    my $prefix = $dcfg->{_prefix};

    my $uppercase = $dcfg->{_uppercase};

    my $new_location = $dcfg->{_newloc};

    my $require = $dcfg->{_require};

    my @parents = $dcfg->{_isa} ? @{$dcfg->{_isa}} : ();

    my @extras = $dcfg->{_extras} ? @{$dcfg->{_extras}} : ();

    my $log = $r->server->log;

    my $uri = $r->uri;

    my ($prehandler, $posthandler, $errorhandler, $rc);

    #---------------------------------------------------------------------
    # do some preliminary stuff...
    #---------------------------------------------------------------------

    $log->info("Using Apache::Dispatch") if $debug > 0;

    # redefine $r as necessary for Apache::Filter 1.013 and above
    if ($filter) {
        $log->info("\tregistering handler with Apache::Filter")
          if $debug > 1;

        # in case we used DispatchFilter directive instead, make sure
        # that other filters in the chain recognize us...
        $r->dir_config->set(Filter => 'On');

        $r   = $r->filter_register;
        $log = $r->server->log;
    }

    $log->info("\tchecking $uri for possible dispatch...")
      if $debug;

    # if the uri contains any characters we don't like, bounce...
    # is this necessary?
    if ($uri =~ m![^\w/-]!) {
        $log->info("\t$uri has bogus characters...")
          if $debug;
        $log->info("Exiting Apache::Dispatch");
        return DECLINED;
    }

    if ($debug > 1) {
        $log->info(
                   "\tapplying the following dispatch rules:",
                   "\n\t\tDispatchPrefix: ",
                   $prefix,
                   "\n\t\tDispatchUpperCase: ",
                   $uppercase,
                   "\n\t\tDispatchStat: ",
                   $stat,
                   "\n\t\tDispatchFilter: ",
                   $filter,
                   "\n\t\tDispatchDebug: ",
                   $debug,
                   "\n\t\tDispatchLocation: ",
                   $new_location ? $new_location : "Unaltered",
                   "\n\t\tDispatchAUTOLOAD: ",
                   $autoload,
                   "\n\t\tDispatchRequire: ",
                   $require,
                   "\n\t\tDispatchExtras: ",
                   (@extras ? (join ' ', @extras) : "None"),
                   "\n\t\tDispatchISA: ",
                   (@parents ? (join ' ', @parents) : "None"),
                  );
    }

    #---------------------------------------------------------------------
    # create the new object
    #---------------------------------------------------------------------

    my ($class, $method) =
      _translate_uri($r, $prefix, $new_location, $log, $debug);

    unless ($class && $method) {
        $log->info("\tclass and method could not be discovered")
          if $debug;
        $log->info("Exiting Apache::Dispatch") if $debug > 0;
        return DECLINED;
    }

    if ($uppercase) {
        $class =~ s/::([a-z])/::\U$1/g;
    }

    my $object = {};

    bless $object, $class;

    #---------------------------------------------------------------------
    # set parent classes for DispatchISA
    #---------------------------------------------------------------------

    if (@parents) {
        $rc = _set_ISA($class, $log, $debug, @parents);

        unless ($rc) {
            $log->error("\tDispatchISA did not return successfully!");
            $log->info("Exiting Apache::Dispatch");
            return DECLINED;
        }
    }

    #---------------------------------------------------------------------
    # require the module if DispatchRequire On
    #---------------------------------------------------------------------

    if ($require) {
        $log->info("\tattempting to require $class...")
          if $debug > 1;

        eval "require $class";

        if ($@) {
            $log->warn("\tcould not require $class: $@");
            $log->info("Exiting Apache::Dispatch");
            return DECLINED;
        }
        else {
            $log->info("\t$class required successfully")
              if $debug > 1;
        }
    }

    #---------------------------------------------------------------------
    # reload the module if DispatchStat On or ISA
    #---------------------------------------------------------------------

    if ($stat eq "ON") {
        $rc = _stat($class, $log, $debug);

        unless ($rc) {
            $log->error("\tDispatchStat did not return successfully!");
            $log->info("Exiting Apache::Dispatch");
            return DECLINED;
        }
    }
    elsif ($stat eq "ISA") {
        $rc = _recurse_stat($class, $log, $debug);

        unless ($rc) {
            $log->error("\tDispatchStat did not return successfully!");
            $log->info("Exiting Apache::Dispatch");
            return DECLINED;
        }
    }

    #---------------------------------------------------------------------
    # see if the handler is a valid method
    # if not, decline the request
    #---------------------------------------------------------------------

    my $handler = _check_dispatch($object, $method, $autoload, $log, $debug);

    if ($handler) {
        $log->info("\t$uri was translated into $class->$method")
          if $debug;
    }
    else {
        $log->info("\t$uri did not result in a valid method")
          if $debug;
        $log->info("Exiting Apache::Dispatch");
        return DECLINED;
    }

    #---------------------------------------------------------------------
    # since the uri is dispatchable, check each of the extras
    #---------------------------------------------------------------------
    foreach my $extra (@extras) {
        if ($extra eq "PRE") {
            $prehandler =
              _check_dispatch($object, "pre_dispatch", $autoload, $log, $debug);
        }
        elsif ($extra eq "POST") {
            $posthandler =
              _check_dispatch($object, "post_dispatch", $autoload, $log,
                              $debug);
        }
        elsif ($extra eq "ERROR") {
            $errorhandler =
              _check_dispatch($object, "error_dispatch", $autoload, $log,
                              $debug);
        }
    }

    #---------------------------------------------------------------------
    # run each of the enabled methods, ignoring pre and post errors
    #---------------------------------------------------------------------

    eval { $object->$prehandler($r) } if $prehandler;

    eval { $rc = $object->$handler($r) };

    if ($errorhandler && ($@ || $rc != OK)) {

        # if the error handler dies we want to catch it, so don't eval
        $rc = $object->$errorhandler($r, $@, $rc);
    }
    elsif ($@) {
        $log->error("$class->$method died: $@");
        $rc = SERVER_ERROR;
    }

    eval { $object->$posthandler($r) } if $posthandler;

    #---------------------------------------------------------------------
    # wrap up...
    #---------------------------------------------------------------------

    $log->info("\tApache::Dispatch is returning $rc")
      if $debug;

    $log->info("Exiting Apache::Dispatch");

    return $rc;
}

#*********************************************************************
# the below methods are not part of the external API
#*********************************************************************

sub _translate_uri {

    #---------------------------------------------------------------------
    # take the uri and return a class and method
    # this method is for internal use only
    #---------------------------------------------------------------------

    my ($r, $prefix, $newloc, $log, $debug) = @_;

    my $uri = $r->uri;

    my $location;

    # change all the / to ::
    (my $class_and_method = $r->uri) =~ s!/!::!g;

    if ($newloc) {
        $log->info("\tmodifying location from ", $r->location, " to $newloc")
          if $debug > 1;
        ($location = $newloc) =~ s!/!::!g;
    }
    else {
        ($location = $r->location) =~ s!/!::!g;
    }

    # strip off the leading and trailing :: if any
    $class_and_method =~ s/^::|::$//g;
    $location         =~ s/^::|::$//g;

    # substitute the prefix for the location
    # <Location /> is a special case that we can deal with
    # (but not advertise :)
    my $times;

    if ($location) {
        $times = $class_and_method =~ s/^\Q$location/$prefix/e;
    }
    else {

        # <Location />
        $prefix .= "::";
        $times = $class_and_method =~ s/^/$prefix/e;
    }

    unless ($times) {
        $log->info("\tLocation substitution failed - uri not translated")
          if $debug > 1;

        return (undef, undef);
    }

    my ($class, $method);

    if ($prefix eq $class_and_method) {
        $method = "dispatch_index";
        $class  = $prefix;
    }
    else {
        ($class, $method) = $class_and_method =~ m/(.*)::(.*)/;
        $method = "dispatch_$method";
    }

    return ($class, $method);
}

sub _check_dispatch {

    #---------------------------------------------------------------------
    # see if class->method() is a valid call
    # this method is for internal use only
    #---------------------------------------------------------------------

    my ($object, $method, $autoload, $log, $debug) = @_;

    my $class = ref($object);

    my $coderef;

    $log->info("\tchecking the validity of $class->$method...")
      if $debug > 1;

    if ($autoload) {
        $coderef = $object->can($method) || $object->can("AUTOLOAD");
    }
    else {
        $coderef = $object->can($method);
    }

    if ($coderef && $debug > 1) {
        $log->info("\t$class->$method is a valid method call");
    }
    elsif ($debug > 1) {
        $log->info("\t$class->$method is not a valid method call");
    }

    return $coderef;
}

sub _stat {

    #---------------------------------------------------------------------
    # stat and reload the module if it has changed...
    # this method is for internal use only
    #---------------------------------------------------------------------
    # Use Apache::Reload here??
    my ($class, $log, $debug) = @_;

    (my $module = $class) =~ s!::!/!g;

    $module .= ".pm";

    $stat{$module} = $^T unless $stat{$module};

    if ($INC{$module}) {
        $log->info("\tchecking $module for reload in pid $$...")
          if $debug > 1;

        my $mtime = (stat $INC{$module})[9];

        unless (defined $mtime && $mtime) {
            $log->warn("Apache::Dispatch cannot find $module!");
            return 1;
        }

        if ($mtime > $stat{$module}) {

            # turn off warnings for this bit...
            local $^W;

            delete $INC{$module};
            eval { require $module };

            if ($@) {
                $log->error("Apache::Dispatch: $module failed reload! $@");
                return undef;
            }
            elsif ($debug) {
                $log->info("\t$module reloaded");
            }
            $stat{$module} = $mtime;
        }
        else {
            $log->info("\t$module not modified")
              if $debug > 1;
        }
    }
    else {
        $log->warn("Apache::Dispatch: $module not in \%INC!");
    }

    return 1;
}

sub _recurse_stat {

    #---------------------------------------------------------------------
    # recurse through all the parent classes of the current class
    # and call _stat on each
    # this method is for internal use only
    #---------------------------------------------------------------------

    my ($class, $log) = @_;

    my $rc = _stat($class, $log);

    return undef unless $rc;

    # turn off strict here so we can get at the class @ISA
    no strict 'refs';

    foreach my $package (@{"${class}::ISA"}) {
        $rc = _recurse_stat($package, $log);
        last unless $rc;
    }

    return $rc;
}

sub _set_ISA {

    #---------------------------------------------------------------------
    # set the ISA array for the class
    # this method is for internal use only
    #---------------------------------------------------------------------

    my ($class, $log, $debug, @parents) = @_;

    # turn off strict here so we can get at the class @ISA
    no strict 'refs';

    if ($debug > 1) {
        $log->info("\t\@ISA for $class currently contains ",
                   (join ", ", @{"${class}::ISA"}));
        $log->info("\tabout to merge ", (join ", ", @parents));
    }

    # only add classes to @ISA if they are not there already
    my %seen;

    @{"${class}::ISA"} = grep !$seen{$_}++, (@{"${class}::ISA"}, @parents);

    return 1;
}

#---------------------------------------------------------------------
# Pure Perl configuration methods
#---------------------------------------------------------------------

sub get_pureperl_config {
    my $r   = shift;
    my $cfg = {};
    no strict 'refs';
    foreach my $key (
        qw(DispatchPrefix DispatchExtras DispatchStat DispatchAUTOLOAD DispatchDebug DispatchISA DispatchLocation DispatchRequire DispatchFilter DispatchUpperCase)
      )
    {
        my $arg = $r->dir_config($key);
        next unless $arg;
        &$key($cfg, undef, $arg);
    }
    return $cfg;
}

#---------------------------------------------------------------------
# Apache configuration methods
#---------------------------------------------------------------------

sub _new {
    return bless {}, shift;
}

sub DIR_CREATE {
    my $class = shift;
    my $self  = $class->_new;

    $self->{_stat}     = "Off";    # no reloading by default
    $self->{_autoload} = 0;        # no autloading by default
    $self->{_require}  = 0;        # no require()ing by default

    #  warn "inside DIR_CREATE";
    return $self;
}

sub DIR_MERGE {
    my ($parent, $current) = @_;
    my %new = (%$parent, %$current);

    #  warn "inside DIR_MERGE";
    return bless \%new, ref($parent);
}

sub DispatchLocation ($$$) {
    my ($cfg, $parms, $arg) = @_;

    $cfg->{_newloc} = $arg;
}

sub DispatchPrefix ($$$) {
    my ($cfg, $parms, $arg) = @_;

    $cfg->{_prefix} = $arg;
}

sub DispatchExtras ($$@) {
    my ($cfg, $parms, $arg) = @_;

    if ($arg =~ m/^(Pre|Post|Error)$/i) {
        push @{$cfg->{_extras}}, uc($arg)
          unless grep /$arg/i, @{$cfg->{_extras}};
    }
    else {
        die "Invalid DispatchExtra $arg!";
    }
}

sub DispatchISA ($$@) {
    my ($cfg, $parms, $arg) = @_;

    push @{$cfg->{_isa}}, $arg
      unless grep /$arg/, @{$cfg->{_isa}};
}

sub DispatchStat ($$$) {
    my ($cfg, $parms, $arg) = @_;

    if ($arg =~ m/^(On|Off|ISA)$/i) {
        $cfg->{_stat} = uc($arg);
    }
    else {
        die "Invalid DispatchStat $arg!";
    }
}

sub DispatchRequire ($$$) {
    my ($cfg, $parms, $arg) = @_;

    $cfg->{_require} = $arg;
}

sub DispatchFilter ($$$) {
    my ($cfg, $parms, $arg) = @_;

    $cfg->{_filter} = $arg;
}

sub DispatchAUTOLOAD ($$$) {
    my ($cfg, $parms, $arg) = @_;

    $cfg->{_autoload} = $arg;
}

sub DispatchDebug ($$$) {
    my ($cfg, $parms, $arg) = @_;

    if ($arg =~ m/[0-9]/) {
        $cfg->{_debug} = $arg;
    }
    else {
        die "Invalid DispatchDebug $arg!";
    }
}

sub DispatchUpperCase ($$$) {
    my ($cfg, $parms, $arg) = @_;

    $cfg->{_uppercase} = $arg;
}

1;

__END__

=head1 NAME

Apache::Dispatch - call PerlHandlers with the ease of Registry scripts

=head1 SYNOPSIS

httpd.conf:

  PerlModule Apache::Dispatch
  PerlModule Bar

  DispatchExtras Pre Post Error
  DispatchStat On
  DispatchISA "My::Utils"
  DispatchAUTOLOAD Off

  <Location /Foo>
    SetHandler perl-script
    PerlHandler Apache::Dispatch

    DispatchPrefix Bar
    DispatchFilter Off
  </Location>

=head1 DESCRIPTION

Apache::Dispatch translates $r->uri into a class and method and runs
it as a PerlHandler.  Basically, this allows you to call PerlHandlers
as you would Regsitry scripts without having to load your httpd.conf
with a slurry of <Location> tags.

=head1 EXAMPLE

  in httpd.conf

    PerlModule Apache::Dispatch
    PerlModule Bar

    <Location /Foo>
      SetHandler perl-script
      PerlHandler Apache::Dispatch

      DispatchPrefix Bar
    </Location>

  in browser:
    http://localhost/Foo/baz

  the results are the same as if your httpd.conf looked like:
    <Location /Foo>
      SetHandler perl-script
      PerlHandler Bar->dispatch_baz
    </Location>

but with the additional security of protecting the class name from
the browser and keeping the method name from being called directly.
Because any class under the Bar:: hierarchy can be called, one
<Location> directive is able to handle all the methods of Bar,
Bar::Baz, etc...

=head1 CONFIGURATION DIRECTIVES

  DispatchPrefix
    The base class to be substituted for the $r->location part of the
    uri.

  DispatchLocation
    Using Apache::Dispatch from a <Directory> directive, either 
    directly or from a .htaccess file, will _require_ the use of
    DispatchLocation, which defines the location from which
    Apache::Dispatch will start class->method() translation.
    For example:

      httpd.conf
        DocumentRoot /usr/local/apache/htdocs
        <Directory /usr/local/apache/htdocs/>
          ...
        <Directory>

     .htaccess (in /usr/local/apache/htdocs/Foo)
        SetHandler perl-script
        PerlHandler Apache::Dispatch
        DispatchPrefix Baz
        DispatchLocation /Foo

    This allows a request to /Foo/Bar/biff to properly map to
    Baz::Bar->biff().  

    While intended specifically for <Directory> configurations, one
    could use DispatchLocation to further obscure uri translations
    within <Location> sections as well by changing the part of
    the uri that is substitued with your module.

  DispatchExtras
    An optional list of extra processing to enable per-request.  If
    the main handler is not a valid method call, the request is 
    declined prior to the execution of any of the extra methods.

      Pre   - eval()s Foo->pre_dispatch($r) prior to dispatching the
              uri.  The $@ of the eval is not checked in any way.

      Post  - eval()s Foo->post_dispatch($r) after dispatching the
              uri.  The $@ of the eval is not checked in any way.

      Error - If the main handler returns other than OK then 
              Foo->error_dispatch($r, $@) is called and return status
              of it is returned instead.  Unlike the pre and post
              processing routines above, error_dispatch is not wrapped
              in an eval, so if it dies, the Apache::Dispatch dies,
              and Apache will process the error using ErrorDocument,
              custom_response(), etc.
              With error_dispatch() disabled, the return status of the
              the main handler is returned to the client.

  DispatchRequire
    An optional directive that enables require()ing of the module that
    is the result of the uri to class->method translation.  This allows
    your configuration to be a bit more dynamic, but also decreases
    security somewhat.  And don't forget that you really should be
    pre-loading frequently used modules in the parent process to reduce
    overhead - DispatchRequire is a directive of conveinence.

      On    - require() the module

      Off   - Do not require() the module (Default)

  DispatchStat
    An optional directive that enables reloading of the module that is
    the result of the uri to class->method translation, similar to
    Apache::Registry, Apache::Reload, or Apache::StatINC.

      On    - Test the called package for modification and reload on
              change

      Off   - Do not test or reload the package (Default)

      ISA   - Test the called package, and all other packages in the
              called package's @ISA, and reload on change

  DispatchAUTOLOAD
    An optional directive that enables unknown methods to use 
    AutoLoader.  It may be applied on a per-server or per-location
    basis and defaults to Off.  Please see the special section on 
    AUTOLOAD below.

      On    - Allow for methods to be defined in AUTOLOAD method

      Off   - Turn off search for AUTOLOAD method (Default)
    
  DispatchISA
    An optional list of parent classes you want your dispatched class
    to inherit from.

  DispatchFilter 
    If you have Apache::Filter 1.013 or above installed, you can take
    advantage of other Apache::Filter aware modules.  Please see the
    section on FILTERING below.  In keeping with Apache::Filter
    standards, PerlSetVar Filter has the same effect as DispatchFilter
    but with lower precedence.

      On    - make the output of your module Apache::Filter aware

      Off   - do not use Apache::Filter (Default)

  DispatchDebug
    Apache::Dispatch uses $r->server->log->info() for debugging.
    Verbose debugging is enabled by setting DispatchDebug to 1.
    Very verbose debugging is enabled at 2.  $Apache::Dispatch::DEBUG
    remains for backward compatibility, but is soon to be deprecated.
    To turn off all debug information set your Apache LogLevel 
    directive above info level.

=head1 SPECIAL CODING GUIDELINES

Migrating to Apache::Dispatch is relatively painless - it requires
only a few minor code changes.  The good news is that once you adapt
code to work with Dispatch, it can be used as a conventional mod_perl
method handler, requiring only a few considerations.  Below are a few
things that require attention.

In the interests of security, all handler methods must be prefixed
with 'dispatch_', which is added to the uri behind the scenes.  Unlike
ordinary mod_perl handlers, for Apache::Dispatch there is no default
method (with a tiny exception - see NOTES below).

Apache::Dispatch uses object oriented calls behind the scenes.  This 
means that you either need to account for your handler to be called
as a method handler, such as

  sub dispatch_bar {
    my $self  = shift;  # your class
    my $r     = shift;
  }

or get the Apache request object directly via

  sub dispatch_bar {
    my $r     = Apache->request;
  }

If you want to use the handler unmodified outside of Apache::Dispatch,
you must do three things:

  prototype your handler:

    sub dispatch_baz ($$) {
      my $self  = shift;
      my $r     = shift;
    }

  change your httpd.conf entry:

    <Location /Foo>
      SetHandler perl-script
      PerlHandler Bar->dispatch_baz
    </Location>

  pre-load your module:
    PerlModule Bar
      or
    PerlRequire startup.pl
    # where startup.pl contains
    # use Bar;

That's it - now the handler can be swapped in and out of Dispatch 
without further modification.  See the Eagle book on method handlers
for more details.

=head1 FILTERING

Apache::Dispatch provides for output filtering using Apache::Filter
1.013 and above.

  <Location /Foo>
    SetHandler perl-script
    PerlHandler Apache::Dispatch Apache::Compress

    DispatchPrefix Bar
    DispatchFilter On
  </Location>

Your handler need do nothing special to make its output the start of
the chain - Apache::Dispatch registers itself with Apache::Filter and
hides the task from your handler.  Thus, any dispatched handler is
automatically Apache::Filter ready without the need for additional
code.

The only caveat is that you must use the request object that is passed
to the handler and not get it directly using Apache->request.

=head1 AUTOLOAD

Support for AUTOLOAD has been made optional, but requires special
care.  Please take the time to read the camel book on using AUTOLOAD
with can() and subroutine declarations (3rd ed pp326-329).

Basically, you declare the methods you want AUTOLOAD to capture by 
name at the top of your script.  This is necessary because can() 
will return true if your class (or any parent class) contains an
AUTOLOAD method, but $AUTOLOAD will only be populated for declared
method calls.  Hence, without a declaration you won't be able to
get at the name of the method you want to AUTOLOAD.

DispatchISA introduced some convenience, but some headaches as well - 
if you inherit from a class that uses AutoLoader then ALL method calls
are true.  And as just explained, AUTOLOAD() will not know what the
called method was.  This may represent a problem if you aren't aware
that, say, CGI.pm uses AutoLoader and spend a few hours trying to 
figure out why all of a sudden every URL under Dispatch is bombing.
You may want to check out NEXT.pm (available from CPAN) for use in 
your AUTOLOAD routines to help circumvent this partucular feature.

If you decide to use DispatchISA it is HIGHLY SUGGESTED that you do so
with DispatchAUTOLOAD Off (which is the default behavior).

=head1 NOTES

If you define a dispatch_index() method calls to /Foo will default to
it.  Unfortunately, this implicit translation only happens at the
highest level - calls to /Foo/Bar will translate to Foo->Bar() (that
is, unless Foo::Bar is your DispatchPrefix, in which case it will
work but /Foo/Bar/Baz will not, etc).  Explicit calls to /Foo/index
follow the normal dispatch rules.

If the uri can be dispatched but contains anything other than
[a-zA-Z0-9_/-] Apache::Dispatch declines to handle the request.

Like everything in perl, the package names are case sensitive.

Warnings have been left on, so if you set an invalid class with
DispatchISA you will see a message like:
  Can't locate package Foo::Bar for @Bar::Baz::ISA at 
  .../Apache/Dispatch.pm line 277.

This is alpha software, and as such has not been tested on multiple
platforms or environments for security, stability or other concerns.
It requires PERL_DIRECTIVE_HANDLERS=1, PERL_LOG_API=1, PERL_HANDLER=1,
and maybe other hooks to function properly.

=head1 FEATURES/BUGS

If a module fails reload under DispatchStat, Apache::Dispatch declines
the request.  This might change to SERVER_ERROR in the future...

=head1 SEE ALSO

perl(1), mod_perl(1), Apache(3), Apache::Filter(3), Apache::Reload(3),
Apache::StatINC(3)

=head1 AUTHOR

Geoffrey Young <geoff@cpan.org>

=head1 COPYRIGHT

Copyright 2001 Geoffrey Young - all rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
