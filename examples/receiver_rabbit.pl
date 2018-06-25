#!/usr/bin/env perl

use warnings;
use strict;
use lib '../lib';
use Daedalus::Hermes;

use Carp;

my $HERMES = Daedalus::Hermes->new('rabbitmq');

my $hermes = $HERMES->new(
    {
        host     => 'localhost',
        user     => 'guest',
        password => 'guest',
        port     => 5672,
        queues   => {
            testqueue => {
                purpose         => "simple_example_queue",
                channel         => 2,
                queue_options   => { durable => 1 },
                amqp_props      => { delivery_mode => 2 },
                publish_options => undef,
            },
        }
    }
);

my $received_message;
while (1) {
    $received_message =
      $hermes->validateAndReceive( { queue => "testqueue" } )->{body};
    carp "$received_message";
}

