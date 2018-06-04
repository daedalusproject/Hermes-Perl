#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More tests => 9;
use Test::Exception;

BEGIN {
    use_ok('Daedalus::Hermes') || print "Bail out!\n";
}

throws_ok { Daedalus::Hermes->new() }
qr/is not defined in 'Daedalus::Hermes'/,
  "Creating an Hermes instance without valid factory date.";

throws_ok { Daedalus::Hermes->new('hermes')->_testConnection() }
qr/Define _testConnection\(\)/,
  "_testConnection is not defined in parent class.";

throws_ok { Daedalus::Hermes->new('hermes')->_send() }
qr/Define _send\(\)/,
  "_send is not defined in parent class.";

throws_ok { Daedalus::Hermes->new('hermes')->_receive() }
qr/Define _receive\(\)/,
  "_receive is not defined in parent class.";

throws_ok { Daedalus::Hermes->new('hermes')->_validateQueue() }
qr/Define _validateQueue\(\)/,
  "_validateQueue is not defined in parent class.";

throws_ok { Daedalus::Hermes->new('hermes')->_processConnectionData() }
qr/Define _processConnectionData\(\)/,
  "_processConnectionData is not defined in parent class.";

throws_ok { Daedalus::Hermes->new('hermes')->_validateMessageData() }
qr/Define _validateMessageData\(\)/,
  "_validateMessageData is not defined in parent class.";

throws_ok { Daedalus::Hermes->new('hermes')->_connect() }
qr/Define _connect\(\)/,
  "_connect is not defined in parent class.";

diag("Testing Daedalus::Hermes $Daedalus::Hermes::VERSION, Perl $], $^X");
