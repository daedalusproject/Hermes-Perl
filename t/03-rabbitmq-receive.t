#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More tests => 5;
use Test::Exception;

use String::Random;

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

throws_ok {
    $hermes->receive();
}
qr/There are is no defined data to connect./,
  "A queue is required to receive a message.";

throws_ok {
    $hermes->receive( {} );
}
qr/There are is no defined queue./, "A queue is required to receive a message.";

throws_ok {
    $hermes->receive( { queue => "nonexistentqueue" } );
}
qr/Queue nonexistentqueue is not defined./,
  "A queue is required to receive a message.";

my $random_string = new String::Random;
my $random        = $random_string->randpattern( 's' x 32 );

my $unique_message = "$message - $random";

$hermes->send( { queue => "testqueue", message => $unique_message } );

ok( $hermes->receive( { queue => "testqueue" } ) eq $unique_message );

diag("Testing Daedalus::Hermes $Daedalus::Hermes::VERSION, Perl $], $^X");
