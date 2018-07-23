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

ok(
    my $hermes = $HERMES->new(
        {
            host     => 'localhost',
            user     => 'guest',
            password => 'guest',
            port     => 5672,
            queues   => {
                testqueue_double => {
                    purpose       => "testqueue_double",
                    channel       => 46,
                    queue_options => { durable => "1" },
                    amqp_props    => { delivery_mode => "2" },
                },
            }
        }
    )
);

my $random_string = new String::Random;
my $random        = $random_string->randpattern( 's' x 32 );

my $unique_message = "$message - $random";

ok(
    $hermes->validateAndSend(
        { queue => "testqueue_double", message => $unique_message }
    )
);

ok(
    $hermes = $HERMES->new(
        {
            host     => 'localhost',
            user     => 'guest',
            password => 'guest',
            port     => 5672,
            queues   => {
                testqueue_double => {
                    purpose       => "testqueue_double",
                    channel       => 46,
                    queue_options => { durable => "1" },
                    amqp_props    => { delivery_mode => "2" },
                },
            }
        }
    )
);

ok(
    $hermes->validateAndSend(
        { queue => "testqueue_double", message => $unique_message }
    )
);

diag("Testing Daedalus::Hermes $Daedalus::Hermes::VERSION, Perl $], $^X");
