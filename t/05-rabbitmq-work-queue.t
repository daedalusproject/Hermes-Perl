#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More tests => 30;
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
                    purpose       => "test_queue_send_receive",
                    channel       => 8,
                    queue_options => { nonsense => {} }
                },
            }
        }
    );

}
qr/Queue options are restricted, "nonsense" in not a valid option./,
  "Queue options names are restricted, nonsense does not exist.";

throws_ok {
    my $hermes = $HERMES->new(
        {
            host     => 'localhost',
            user     => 'guest',
            password => 'guest',
            port     => 5672,
            queues   => {
                testqueue => {
                    purpose       => "test_queue_send_receive",
                    channel       => 9,
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
                    purpose       => "test_queue_send_receive",
                    channel       => 10,
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
                    purpose       => "test_queue_send_receive",
                    channel       => 11,
                    queue_options => { passive => 2 }
                },
            }
        }
    );

}
qr/Queue options values must have boolean values, 0 or 1. "passive" value is invalid./,
  "Queue options must be 0 or 1.";

throws_ok {
    my $hermes = $HERMES->new(
        {
            host     => 'localhost',
            user     => 'guest',
            password => 'guest',
            port     => 5672,
            queues   => {
                testqueue => {
                    purpose       => "test_queue_send_receive",
                    channel       => 12,
                    queue_options => { passive => 1, durable => 2 }
                },
            }
        }
    );

}
qr/Queue options values must have boolean values, 0 or 1. "durable" value is invalid./,
  "Queue options must be 0 or 1.";

# Publish options

throws_ok {
    my $hermes = $HERMES->new(
        {
            host     => 'localhost',
            user     => 'guest',
            password => 'guest',
            port     => 5672,
            queues   => {
                testqueue => {
                    purpose       => "test_queue_send_receive",
                    channel       => 13,
                    queue_options => { passive => 1, durable => 1 },
                    publish_options => { nonsense => 1 },
                }
            }
        }
    );

}
qr/Publish options are restricted, "nonsense" in not a valid option./,
  "Publish options names are restricted, nonsense does not exist.";

throws_ok {
    my $hermes = $HERMES->new(
        {
            host     => 'localhost',
            user     => 'guest',
            password => 'guest',
            port     => 5672,
            queues   => {
                testqueue => {
                    purpose       => "test_queue_send_receive",
                    channel       => 14,
                    queue_options => { passive => 1, durable => 1 },
                    publish_options => { mandatory => "nonsense" },
                }
            }
        }
    );

}
qr/Some publish options values must have boolean values, 0 or 1. "mandatory" value is invalid./,
  "Execept 'exchange', publish options must have boolean values.";

throws_ok {
    my $hermes = $HERMES->new(
        {
            host     => 'localhost',
            user     => 'guest',
            password => 'guest',
            port     => 5672,
            queues   => {
                testqueue => {
                    purpose         => "test_queue_send_receive",
                    channel         => 15,
                    queue_options   => { passive => 1, durable => 1 },
                    publish_options => { mandatory => 1, exchange => 1 },
                }
            }
        }
    );

}
qr/"exchange" publish option is invalid, must be a string./,
  "'exchange'  publish option must a string.";

ok(
    $HERMES->new(
        {
            host     => 'localhost',
            user     => 'guest',
            password => 'guest',
            port     => 5672,
            queues   => {
                testqueue => {
                    purpose       => "test_queue_send_receive",
                    channel       => 16,
                    queue_options => { passive => 1, durable => 0 }
                },
            }
        }
      )

);

ok(
    $HERMES->new(
        {
            host     => 'localhost',
            user     => 'guest',
            password => 'guest',
            port     => 5672,
            queues   => {
                testqueue => {
                    purpose       => "test_queue_send_receive",
                    channel       => 17,
                    queue_options => { passive => 0, durable => 0 }
                },
            }
        }
      )

);

ok(
    $HERMES->new(
        {
            host     => 'localhost',
            user     => 'guest',
            password => 'guest',
            port     => 5672,
            queues   => {
                testqueue => {
                    purpose       => "test_queue_send_receive",
                    channel       => 18,
                    queue_options => { passive => 0, durable => 0 },
                    publish_options => { mandatory => 0 }
                },
            }
        }
      )

);

ok(
    $HERMES->new(
        {
            host     => 'localhost',
            user     => 'guest',
            password => 'guest',
            port     => 5672,
            queues   => {
                testqueue => {
                    purpose       => "test_queue_send_receive",
                    channel       => 19,
                    queue_options => { passive => 0, durable => 0 },
                    publish_options =>
                      { mandatory => 0, exchange => "amq.direct" }
                },
            }
        }
      )

);

# AMQP props
throws_ok {
    my $hermes = $HERMES->new(
        {
            host     => 'localhost',
            user     => 'guest',
            password => 'guest',
            port     => 5672,
            queues   => {
                testqueue => {
                    purpose       => "test_queue_send_receive",
                    channel       => 20,
                    queue_options => { passive => 1, durable => 1 },
                    publish_options => { mandatory => 1 },
                    amqp_props      => { nonsense  => 1 },
                }
            }
        }
    );

}
qr/AMQP props are restricted, "nonsense" in not a valid prop./,
  "AMQP props names are restricted, nonsense does not exist.";

throws_ok {
    my $hermes = $HERMES->new(
        {
            host     => 'localhost',
            user     => 'guest',
            password => 'guest',
            port     => 5672,
            queues   => {
                testqueue => {
                    purpose       => "test_queue_send_receive",
                    channel       => 21,
                    queue_options => { passive => 1, durable => 1 },
                    publish_options => { mandatory => 1 },
                    amqp_props      => { priority  => "nonsense" },
                }
            }
        }
    );

}
qr/Some AMQP props values must be an integer. "priority" value is invalid./,
  "'priority' prop must have integer values.";

throws_ok {
    my $hermes = $HERMES->new(
        {
            host     => 'localhost',
            user     => 'guest',
            password => 'guest',
            port     => 5672,
            queues   => {
                testqueue => {
                    purpose       => "test_queue_send_receive",
                    channel       => 22,
                    queue_options => { passive => 1, durable => 1 },
                    publish_options => { mandatory => 1 },
                    amqp_props      => { priority  => 2, content_type => 1 },
                }
            }
        }
    );
}
qr/Some AMQP props values must be strings. "content_type" value is invalid./,
  "'content_type'  prop must a string.";

throws_ok {
    my $hermes = $HERMES->new(
        {
            host     => 'localhost',
            user     => 'guest',
            password => 'guest',
            port     => 5672,
            queues   => {
                testqueue => {
                    purpose       => "test_queue_send_receive",
                    channel       => 23,
                    queue_options => { passive => 1, durable => 1 },
                    publish_options => { mandatory => 1 },
                    amqp_props      => {
                        priority       => 1,
                        correlation_id => "1",
                        headers        => "nonsense"
                    },
                }
            }
        }
    );

}
qr/Some AMQP props values must be a hash. "headers" value is invalid./,
  "'headers'prop must be a hash.";

ok(
    $HERMES->new(
        {
            host     => 'localhost',
            user     => 'guest',
            password => 'guest',
            port     => 5672,
            queues   => {
                testqueue => {
                    purpose       => "test_queue_send_receive",
                    channel       => 24,
                    queue_options => { passive => 0, durable => 0 },
                    publish_options =>
                      { mandatory => 0, exchange => "amq.direct" },
                    amqp_props => {
                        priority       => 1,
                        correlation_id => "1",
                        headers        => { something => 1 }
                    },
                },
            }
        }
    )
);

# Basic qos options
throws_ok {
    my $hermes = $HERMES->new(
        {
            host     => 'localhost',
            user     => 'guest',
            password => 'guest',
            port     => 5672,
            queues   => {
                testqueue => {
                    purpose       => "test_queue_send_receive",
                    channel       => 25,
                    queue_options => { passive => 1, durable => 1 },
                    publish_options   => { mandatory => 1 },
                    amqp_props        => { priority  => 1 },
                    amqp_props        => { priority  => 1 },
                    basic_qos_options => { nonsense  => 1 },
                }
            }
        }
    );

}
qr/Basic qos options are restricted, "nonsense" in not a valid option./,
  "Basic qos options are restricted, nonsense does not exist.";

throws_ok {
    my $hermes = $HERMES->new(
        {
            host     => 'localhost',
            user     => 'guest',
            password => 'guest',
            port     => 5672,
            queues   => {
                testqueue => {
                    purpose       => "test_queue_send_receive",
                    channel       => 26,
                    queue_options => { passive => 1, durable => 1 },
                    publish_options   => { mandatory      => 1 },
                    amqp_props        => { priority       => 1 },
                    amqp_props        => { priority       => 1 },
                    basic_qos_options => { prefetch_count => "1mnotanum3r" },
                }
            }
        }
    );

}
qr/Some Basic qos options must be an integer. "prefetch_count" value is invalid./,
  "'prefetch_count' option must have integer value.";

throws_ok {
    my $hermes = $HERMES->new(
        {
            host     => 'localhost',
            user     => 'guest',
            password => 'guest',
            port     => 5672,
            queues   => {
                testqueue => {
                    purpose       => "test_queue_send_receive",
                    channel       => 27,
                    queue_options => { passive => 1, durable => 1 },
                    publish_options   => { mandatory      => 1 },
                    amqp_props        => { priority       => 1 },
                    amqp_props        => { priority       => 1 },
                    basic_qos_options => { prefetch_count => 1, global => 2 },
                }
            }
        }
    );

}
qr/Some Basic qos options must have a bool value. "global" value is invalid./,
  "'global' option must have boolean value.";

ok(
    my $hermes = $HERMES->new(
        {
            host     => 'localhost',
            user     => 'guest',
            password => 'guest',
            port     => 5672,
            queues   => {
                testqueue => {
                    purpose       => "test_queue_send_receive",
                    channel       => 28,
                    queue_options => { passive => 1, durable => 1 },
                    publish_options   => { mandatory      => 1 },
                    amqp_props        => { priority       => 1 },
                    amqp_props        => { priority       => 1 },
                    basic_qos_options => { prefetch_count => 1, global => 0 },
                }
            }
        }
      )

);

# Basic consume options
throws_ok {
    my $hermes = $HERMES->new(
        {
            host     => 'localhost',
            user     => 'guest',
            password => 'guest',
            port     => 5672,
            queues   => {
                testqueue => {
                    purpose       => "test_queue_send_receive",
                    channel       => 29,
                    queue_options => { passive => 1, durable => 1 },
                    publish_options   => { mandatory      => 1 },
                    amqp_props        => { priority       => 1 },
                    amqp_props        => { priority       => 1 },
                    basic_qos_options => { prefetch_count => 1, global => 0 },
                    consume_options   => { nonsense       => 0 },
                }
            }
        }
    );

}
qr/Consume options are restricted, "nonsense" in not a valid option./,
  "Consume options are restricted, nonsense does not exist.";

throws_ok {
    my $hermes = $HERMES->new(
        {
            host     => 'localhost',
            user     => 'guest',
            password => 'guest',
            port     => 5672,
            queues   => {
                testqueue => {
                    purpose       => "test_queue_send_receive",
                    channel       => 30,
                    queue_options => { passive => 1, durable => 1 },
                    publish_options   => { mandatory      => 1 },
                    amqp_props        => { priority       => 1 },
                    amqp_props        => { priority       => 1 },
                    basic_qos_options => { prefetch_count => 1, global => 0 },
                    consume_options   => { no_local       => '1mn0tanumb3r' },
                }
            }
        }
    );

}
qr/Consume options must have a bool value. "no_local" value is invalid./,
  "'no_local' option must have boolean value.";

throws_ok {
    my $hermes = $HERMES->new(
        {
            host     => 'localhost',
            user     => 'guest',
            password => 'guest',
            port     => 5672,
            queues   => {
                testqueue => {
                    purpose       => "test_queue_send_receive",
                    channel       => 40,
                    queue_options => { passive => 1, durable => 1 },
                    publish_options   => { mandatory      => 1 },
                    amqp_props        => { priority       => 1 },
                    amqp_props        => { priority       => 1 },
                    basic_qos_options => { prefetch_count => 1, global => 0 },
                    consume_options   => { no_local       => 2 },
                }
            }
        }
    );

}
qr/Consume options must have a bool value. "no_local" value is invalid./,
  "'no_local' option must have boolean value.";

ok(
    my $hermes_work = $HERMES->new(
        {
            host     => 'localhost',
            user     => 'guest',
            password => 'guest',
            port     => 5672,
            queues   => {
                testqueue => {
                    purpose       => "test_queue_send_receive",
                    channel       => 41,
                    queue_options => { passive => 1, durable => 1 },
                    publish_options   => { mandatory      => 1 },
                    amqp_props        => { priority       => 1 },
                    basic_qos_options => { prefetch_count => 1, global => 0 },
                    consume_options   => { no_local       => 0 },
                }
            }
        }
      )

);

my $hermes_work_sender = $HERMES->new(
    {
        host     => 'localhost',
        user     => 'guest',
        password => 'guest',
        port     => 5672,
        queues   => {
            testqueue => {
                purpose           => "test_work_queue",
                channel           => 42,
                queue_options     => { durable => 1 },
                amqp_props        => { delivery_mode => 2 },
                publish_options   => undef,
                consume_options   => { no_ack => 0 },
                basic_qos_options => { prefetch_count => 1 },
            },
        }
    }
);

my $random_string = new String::Random;
my $random        = $random_string->randpattern( 's' x 32 );

my $unique_message = "$message - $random";

ok(
    $hermes_work_sender->validateAndSend(
        { queue => "testqueue", message => $unique_message }
    )
);

my $response =
  $hermes_work_sender->validateAndReceive( { queue => "testqueue" } );

ok( $response->{body} eq $unique_message );

ok( $hermes_work_sender->sendACK( { queue => "testqueue" }, $response ) );

my $hermes_work_sender_no_ack = $HERMES->new(
    {
        host     => 'localhost',
        user     => 'guest',
        password => 'guest',
        port     => 5672,
        queues   => {
            testqueue => {
                purpose => "test_work_queue_no_ack",
                channel => 43,
            },
        }
    }
);

$random = $random_string->randpattern( 's' x 32 );

$unique_message = "$message - $random";

$hermes_work_sender_no_ack->validateAndSend(
    { queue => "testqueue", message => $unique_message } );

my $received_message =
  $hermes_work_sender_no_ack->validateAndReceive( { queue => "testqueue" } );

throws_ok {
    $hermes_work_sender_no_ack->sendACK( { queue => "testqueue" }, $response );
}
qr/This queue sends ACK messages automatically, it is not possible to send ACK message again./,
  "It is not allowed to send ack if it is automatically sent.";

diag("Testing Daedalus::Hermes $Daedalus::Hermes::VERSION, Perl $], $^X");
