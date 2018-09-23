#!/usr/bin/env perl

use blib;

use strict;
use warnings;
use X11::Motif;

my $toplevel = X::Toolkit::initialize("Example");

# create_widget() is an alias for give()

my $form = $toplevel->create_widget("Form");         # -Form would also work
my $hello = $form->create_widget( "Label", -text => 'Hello, world!' );
my $ok = $form->create_widget( "Button", -text => 'OK', -command => sub { exit } );

$form->arrange( -fill => 'xy', -bottom => [ $ok, $hello ] );

$toplevel->handle();
