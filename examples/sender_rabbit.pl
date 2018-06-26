#!/usr/bin/env perl

use warnings;
use strict;
use lib '../lib';
use Daedalus::Hermes;

use String::Random;

my $argsize;
$argsize = scalar @ARGV;
my $name;

if ( $argsize == 1 ) {
    $name = $ARGV[0];
}
else {
    $name = "None";
}

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

my $random_string = new String::Random;
my $random        = $random_string->randpattern( 's' x 32 );

$hermes->validateAndSend(
    {
        queue   => "testqueue",
        message => "$name -> Ground Control to Major Tom. $random"
    }
);

