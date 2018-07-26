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
            daedalus_core_notifications => {
                purpose           => "daedalus_core_notifications",
                channel           => 45,
                queue_options     => { durable => 1, auto_delete => 0 },
                amqp_props        => { delivery_mode => 1 },
                consume_options   => { no_ack => 0 },
                basic_qos_options => { prefetch_count => 1 },
                publish_options   => undef,
            },
        }
    }
);

my $received_message;
while (1) {
    $received_message =
      $hermes->validateAndReceive( { queue => "daedalus_core_notifications" } )
      ->{body};
    carp "$received_message";
}
