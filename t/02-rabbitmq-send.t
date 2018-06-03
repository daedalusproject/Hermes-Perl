#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More tests => 1;
use Test::Exception;

BEGIN {
    use_ok('Daedalus::Hermes') || print "Bail out!\n";
}

my $HERMES = Daedalus::Hermes->new('rabbitmq');

#my $hermes_rabbitmq =     $HERMES->new(
#        {
#            host     => 'localhost',
#            user     => 'guest',
#            password => 'guest',
#            port     => 5672
#            queues => {}
#        }
#    );
#
#$hermes_rabbitmq->send({})

diag("Testing Daedalus::Hermes $Daedalus::Hermes::VERSION, Perl $], $^X");
