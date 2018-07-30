#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More tests => 2;
use Test::Exception;

use String::Random;

use Data::Dumper;

BEGIN {
    use_ok('Daedalus::Hermes') || print "Bail out!\n";
}

my $message = "Ground Control to Major Tom.";

my $HERMES = Daedalus::Hermes->new('rabbitmq');

my $hermes_config =
  Daedalus::Hermes::parse_hermes_config("t/files/hermesrabbit02.xml");

my $hermes = $HERMES->new( $hermes_config->{config}, );

my $random_string = new String::Random;
my $random        = $random_string->randpattern( 's' x 32 );

my $unique_message = "$message - $random";

$hermes->validateAndSend(
    { queue => "test_queue_send_receive", message => $unique_message } );

ok( $hermes->validateAndReceive( { queue => "test_queue_send_receive" } )
      ->{body} eq $unique_message );

diag("Testing Daedalus::Hermes $Daedalus::Hermes::VERSION, Perl $], $^X");
