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
            testqueue => { purpose => "test_queue_send_receive", channel => 7 },
        }
    }
);

throws_ok {
    $hermes->validateAndReceive();
}
qr/There are is no defined data to connect./,
  "A queue is required to receive a message.";

throws_ok {
    $hermes->validateAndReceive( {} );
}
qr/There are is no defined queue./, "A queue is required to receive a message.";

throws_ok {
    $hermes->validateAndReceive( { queue => "nonexistentqueue" } );
}
qr/Queue nonexistentqueue is not defined./,
  "A queue is required to receive a message.";

my $random_string = new String::Random;
my $random        = $random_string->randpattern( 's' x 32 );

my $unique_message = "$message - $random";

$hermes->validateAndSend(
    { queue => "testqueue", message => $unique_message } );

ok( $hermes->validateAndReceive( { queue => "testqueue" } )->{body} eq
      $unique_message );

diag("Testing Daedalus::Hermes $Daedalus::Hermes::VERSION, Perl $], $^X");
