#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More tests => 2;
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

diag("Testing Daedalus::Hermes $Daedalus::Hermes::VERSION, Perl $], $^X");
