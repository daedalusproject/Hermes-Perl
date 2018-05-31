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

throws_ok { Daedalus::Hermes->call($data) }
qr/Failed to instance Hermes. No brokerType found./,
  "Creating and Hermes instance without BrokerTyoe attribute should fail.";

$data->{brokerType} = 'RabbitMQ';

my $hermes = Daedalus::Hermes->call($data);

diag("Testing Daedalus::Hermes $Daedalus::Hermes::VERSION, Perl $], $^X");
