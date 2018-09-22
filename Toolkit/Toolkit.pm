package X11::Toolkit;

# Copyright 1997, 1998 by Ken Fox

use X11::Lib qw(:private);
use X11::Toolkit::Widget;
use X11::Toolkit::WidgetClass;
use X11::ToolkitCons;

use strict;
use vars qw($VERSION @ISA);

BEGIN {
    $VERSION = 1.0;
    @ISA = qw();
}

sub beta_version { 3 };

sub import {
    my $module = shift;
    my %done;

    foreach my $sym (@_) {
	next if ($done{$sym});

	if ($sym eq ':Xt') {
	    export_pattern(\%X::Toolkit::, '^Xt');
	    export_pattern(\%X::Toolkit::Context::, '^Xt');
	    export_pattern(\%X::Toolkit::Widget::, '^Xt');
	}
	elsif ($sym eq ':private') {
	    export_symbol(\%X11::Lib::, 'export_pattern');
	    export_symbol(\%X11::Lib::, 'export_symbol');
	    export_symbol(\%X11::Lib::, 'alias_trimmed_pattern');
	}
	else {
	    export_symbol(\%X::Toolkit::, $sym) ||
	    export_symbol(\%X::Toolkit::Widget, $sym) ||
	    export_symbol(\%X::Toolkit::Context, $sym);
	}

	$done{$sym} = 1;
    }
}

my $finished_standard_aliases = 0;

sub use_standard_aliases {
    if (!$finished_standard_aliases) {
	$finished_standard_aliases = 1;
	alias_trimmed_pattern("X::Toolkit", \%X::Toolkit::, '^Xt');
	alias_trimmed_pattern("X::Toolkit::Widget", \%X::Toolkit::Widget::, '^Xt');
	alias_trimmed_pattern("X::Toolkit::Context", \%X::Toolkit::Context::, '^Xt');
    }
}

package X::Toolkit;

use Carp;

sub initialize {
    my $app_class = shift;
    my $display_name = '';
    my $colors = '-default';
    my $writable_colormap = 0;

    my $name;
    my $value;

    # this is ugly.  toolkit initialization should use the widget resource
    # initialization routines with the AppShell as the widget class.  FIXME
    # -colors and -colormap could be pseudo-resources then.

    while (@_) {
	$name = shift;
	$value = shift;
	if ($name eq '-colors') {
	    $colors = $value;
	}
	elsif ($name eq '-colormap') {
	    if ($value =~ /^-?readonly/) {
		$writable_colormap = 0;
	    }
	    elsif ($value =~ /^-?writable/) {
		$writable_colormap = 1;
	    }
	}
	elsif ($name eq '-display') {
	    $display_name = $value;
	}
    }

    priv_initialize($app_class, $display_name, $colors, $writable_colormap);
}

# ================================================================================
# X Toolkit compatibility functions
#
# The intention is to support the Xt interface as faithfully as
# possible.  Where an obvious C limitation can be easily removed,
# in creating ArgLists for example, the Xt interface is *slightly*
# improved.

sub XtCreateWidget {
    my $name = shift;
    my $type = shift;
    my $parent = shift;

    if (ref $type ne 'X::Toolkit::WidgetClass') {
	croak "$type is not a widget class";
    }

    my $type_name = $type->name();

    my %resources = ();
    my %callbacks;

    X::Toolkit::Widget::build_strict_resource_table($type_name, $parent->Class()->name(),
						    \%resources, \%callbacks, @_);

    my $child = X::Toolkit::priv_XtCreateWidget($name, $type, $parent, %resources);

    if (!defined $child) {
	carp "couldn't create $type_name widget $name";
    }

    $child;
}

sub XtCreateManagedWidget {
    my $w = XtCreateWidget(@_);
    $w->ManageChild;
    $w;
}

sub XtCreatePopupShell {
    my $name = shift;
    my $type = shift;
    my $parent = shift;

    if (ref $type ne 'X::Toolkit::WidgetClass') {
	croak "$type is not a widget class";
    }

    my $type_name = $type->name();

    my %resources = ();
    my %callbacks;

    X::Toolkit::Widget::build_strict_resource_table($type_name, $parent->Class()->name(),
						    \%resources, \%callbacks, @_);

    # priv_XtCreatePopupShell jumps through hoops to use the same visual as
    # used by its application shell.  perhaps that code should be moved here?
    # it would eliminate the need for over-allocating all the temporary
    # resource/value arglists.

    my $child = X::Toolkit::priv_XtCreatePopupShell($name, $type, $parent, %resources);

    if (!defined $child) {
	carp "couldn't create $type_name widget $name";
    }

    $child;
}

1;
