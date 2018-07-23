#!/usr/bin/env perl

use warnings;
use strict;
use lib '../lib';
use Daedalus::Hermes;

use String::Random;

my $message = "Ground Control to Major Tom.";

my $HERMES = Daedalus::Hermes->new('rabbitmq');

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
);

my $random_string = new String::Random;
my $random        = $random_string->randpattern( 's' x 32 );

my $unique_message = "$message - $random";

$hermes->validateAndSend(
    { queue => "testqueue_double", message => $unique_message } );

undef $hermes;

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
);

$hermes->validateAndSend(
    { queue => "testqueue_double", message => $unique_message } );

