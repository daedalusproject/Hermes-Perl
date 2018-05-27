#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Daedalus::Hermes' ) || print "Bail out!\n";
}

diag( "Testing Daedalus::Hermes $Daedalus::Hermes::VERSION, Perl $], $^X" );
