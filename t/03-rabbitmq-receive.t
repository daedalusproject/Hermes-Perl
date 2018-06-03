#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More tests => 3;
use Test::Exception;

BEGIN {
    use_ok('Daedalus::Hermes') || print "Bail out!\n";
}

my $message = "Ground Control to Major Tom.";

my $HERMES = Daedalus::Hermes->new('rabbitmq');

my $hermes = $HERMES->new(
    {
        host     => 'localhost',
        user     => 'guest',
        password => 'guest',
        port     => 5672,
        queues   => {
            testqueue => { purpose => "test_queue_sed_receive", channel => 2 },
        }
    }
);

$hermes->send( { queue => "testqueue", message => $message } );

throws_ok {
    $hermes->receive();
}
qr/There are is no defined data to connect./,
  "A queue is required to receive a message.";

ok( $hermes->receive( { queue => "testqueue" } ) eq $message );

diag("Testing Daedalus::Hermes $Daedalus::Hermes::VERSION, Perl $], $^X");
