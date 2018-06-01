#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More tests => 2;
use Test::Exception;

BEGIN {
    use_ok('Daedalus::Hermes') || print "Bail out!\n";
}

throws_ok { Daedalus::Hermes->new() }
qr/is not defined in 'Daedalus::Hermes'/,
  "Creating an Hermes instance without valid factory date.";

diag("Testing Daedalus::Hermes $Daedalus::Hermes::VERSION, Perl $], $^X");
