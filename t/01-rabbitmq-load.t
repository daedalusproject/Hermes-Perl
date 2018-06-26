#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More tests => 13;
use Test::Exception;

BEGIN {
    use_ok('Daedalus::Hermes') || print "Bail out!\n";
}

my $HERMES = Daedalus::Hermes->new('rabbitmq');

throws_ok { $HERMES->new(); }
qr/\(password\) is required at constructor/,
"Creating and Daedalus::Hermes::RabbitMQ instance without user or password should fail.";

throws_ok { $HERMES->new( { password => 'guest' } ); }
qr/\(queues\) is required at constructor/,
"Creating and Daedalus::Hermes::RabbitMQ instance without queues should fail.";

throws_ok { $HERMES->new( { password => 'guest', queues => {} } ); }
qr/\(user\) is required at constructor/,
  "Creating and Daedalus::Hermes::RabbitMQ instance without user should fail.";

throws_ok {
    $HERMES->new( { user => 'guest', password => 'guest', queues => {} } );
}
qr/There is no defined queues./,
"Creating and Daedalus::Hermes::RabbitMQ instance with empty queues should fail.";

throws_ok {
    $HERMES->new(
        { user => 'guest', password => 'guest', queues => { testqueue => {} } }
    );
}
qr/testqueue has no purpose defined/,
"Creating and Daedalus::Hermes instance with queues with no purpose whould fail.";

throws_ok {
    $HERMES->new(
        {
            user     => 'guest',
            password => 'guest',
            queues   => { testqueue => { purpose => "send things" } }
        }
    );
}
qr/testqueue purpose is not allowed to contain spaces/,
  "'purpose' field is not allowed to contain spaces.";

throws_ok {
    $HERMES->new(
        {
            user     => 'guest',
            password => 'guest',
            queues   => { testqueue => {}, testqueue2 => {} }
        }
    );
}
qr/has no purpose defined/,
  "Daedalus::Hermes::Perl constructor shows all found errors.";

throws_ok {
    $HERMES->new(
        {
            user     => 'guest',
            password => 'guest',
            queues =>
              { testqueue => { purpose => "send_things" }, testqueue2 => {} }
        }
    );
}
qr/testqueue2 has no purpose defined/,
  "Daedalus::Hermes::Perl constructor checks all queues.";

throws_ok {
    $HERMES->new(
        {
            host     => 'localhost',
            user     => 'guest',
            password => 'guest',
            port     => 5672,
            queues   => {
                testqueue  => { purpose => "test_queue" },
                testqueue2 => { purpose => "other_test_queue" }
            }
        }
    );
}
qr/A channel number is required for/,
  "Daedalus::Hermes::RabbitMQ requires channels.";

throws_ok {
    $HERMES->new(
        {
            host     => 'localhost',
            user     => 'guest',
            password => 'guest',
            port     => 5672,
            queues   => {
                testqueue  => { purpose => "test_queue",       channel => -1 },
                testqueue2 => { purpose => "other_test_queue", channel => 1 },
            }
        }
    );
}
qr/Channel must be positive number in/, "Channels has to be positive integers.";

throws_ok {
    $HERMES->new(
        {
            host     => 'localhost',
            user     => 'guest',
            password => 'guest',
            port     => 5672,
            queues   => {
                testqueue  => { purpose => "test_queue",       channel => 2 },
                testqueue2 => { purpose => "other_test_queue", channel => 3 },
                testqueue3 =>
                  { purpose => "yet_other_test_queue", channel => 2 },
            }
        }
    );
}
qr/There are one or more queues sharing channel/,
  "Two queues can't use the same channel";

ok(
    $HERMES->new(
        {
            host     => 'localhost',
            user     => 'guest',
            password => 'guest',
            port     => 5672,
            queues   => {
                testqueue  => { purpose => "test_queue",       channel => 4 },
                testqueue2 => { purpose => "other_test_queue", channel => 5 },
                testqueue3 =>
                  { purpose => "yet_other_test_queue", channel => 6 },
            }
        }
    ),
    "Daedalus::Hermes::RabbitMQ should be instanced."
);

diag("Testing Daedalus::Hermes $Daedalus::Hermes::VERSION, Perl $], $^X");
