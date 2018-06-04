#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More tests => 5;
use Test::Exception;

BEGIN {
    use_ok('Daedalus::Hermes') || print "Bail out!\n";
}

my $HERMES = Daedalus::Hermes->new('rabbitmq');

my $hermes = $HERMES->new(
    {
        host     => 'localhost',
        user     => 'guest',
        password => 'guest',
        port     => 5672,
        queues   => {
            testqueue => { purpose => "test_queue", channel => 1 },
        }
    }
);

throws_ok {
    $hermes->validateAndSend();
}
qr/There are is no defined data for sending any message./,
  "A queue is required to send a message.";

throws_ok {
    $hermes->validateAndSend( { queue => "testqueue" } );
}

qr/There are is no defined queue or message, cannot send any message./,
  "Of course, to send a message you need something to send";

throws_ok {
    $hermes->validateAndSend(
        { queue => "nonexistentqueue", message => "Not senging this" } );
}

qr/Queue nonexistentqueue is not defined in Daedalus::Hermes::RabbitMQ configuration, cannot send any message./,
  "Selected queue has to be definned in Hermes instance.";

ok(
    $hermes->validateAndSend(
        { queue => "testqueue", message => "Ground Control to Major Tom." }
    )
);

diag("Testing Daedalus::Hermes $Daedalus::Hermes::VERSION, Perl $], $^X");
