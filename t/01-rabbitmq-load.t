#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More tests => 4;
use Test::Exception;

BEGIN {
    use_ok('Daedalus::Hermes') || print "Bail out!\n";
}

my $HERMES = Daedalus::Hermes->new('rabbitmq');

throws_ok { $HERMES->new(); }
qr/\(password\) is required at constructor/,
"Creating and Daedalus::Hermes::RabbitMQ instance without user or password should fail.";

throws_ok { $HERMES->new( { password => 'guest' } ); }
qr/\(user\) is required at constructor/,
  "Creating and Daedalus::Hermes::RabbitMQ instance without user should fail.";

ok(
    $HERMES->new( { user => 'guest', password => 'guest' } ),
    "Daedalus::Hermes::RabbitMQ can be instanced."
);

diag("Testing Daedalus::Hermes $Daedalus::Hermes::VERSION, Perl $], $^X");
