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

throws_ok {
    my $hermes = $HERMES->new(
        {
            host     => 'localhost',
            user     => 'guest',
            password => 'guest',
            port     => 5672,
            queues   => {
                testqueue => {
                    purpose       => "test_queue_sed_receive",
                    channel       => 2,
                    queue_options => { nonsense => {} }
                },
            }
        }
    );

}
qr/Queue options are restricted, "nonsense" in not a valid option./,
  "Queue options names are restricted, nonsense does not exists.";

throws_ok {
    my $hermes = $HERMES->new(
        {
            host     => 'localhost',
            user     => 'guest',
            password => 'guest',
            port     => 5672,
            queues   => {
                testqueue => {
                    purpose       => "test_queue_sed_receive",
                    channel       => 2,
                    queue_options => { nonsense => 1 }
                },
            }
        }
    );

}
qr/Queue options are restricted, "nonsense" in not a valid option./,
"Queue options names are restricted, nonsense does not exists unles it has a valid value.";

throws_ok {
    my $hermes = $HERMES->new(
        {
            host     => 'localhost',
            user     => 'guest',
            password => 'guest',
            port     => 5672,
            queues   => {
                testqueue => {
                    purpose       => "test_queue_sed_receive",
                    channel       => 2,
                    queue_options => { passive => "nonsense" }
                },
            }
        }
    );

}
qr/Queue options values must have boolean values, 0 or 1. "passive" value is invalid./,
  "Queue options must be boolean, passive has to be 0 or 1.";

throws_ok {
    my $hermes = $HERMES->new(
        {
            host     => 'localhost',
            user     => 'guest',
            password => 'guest',
            port     => 5672,
            queues   => {
                testqueue => {
                    purpose       => "test_queue_sed_receive",
                    channel       => 2,
                    queue_options => { passive => 2 }
                },
            }
        }
    );

}
qr/Queue options values must have boolean values, 0 or 1. "passive" value is invalid./,
  "Queue options must be 0 or 1.";

diag("Testing Daedalus::Hermes $Daedalus::Hermes::VERSION, Perl $], $^X");
