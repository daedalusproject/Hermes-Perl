#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More tests => 2;
use Test::Exception;

BEGIN {
    use_ok('Daedalus::Hermes') || print "Bail out!\n";
}

my $data = {};

$data->{brokerType} = 'RabbitMQ';

my $hermes = Daedalus::Hermes->call($data);

ok( $hermes->testConnection() );

diag("Testing Daedalus::Hermes $Daedalus::Hermes::VERSION, Perl $], $^X");
