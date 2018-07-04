package Daedalus::Hermes;

use 5.006;
use strict;
use warnings;

use Carp qw(croak);

use base qw( Class::Factory  );
use Moose;
use Moose::Util::TypeConstraints;
use XML::Parser;
use XML::SimpleObject;

use namespace::autoclean;

use Data::Dumper;

=head1 NAME

Daedalus::Hermes - The great new Daedalus::Hermes!

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

Service that provides communication between Daedalus Project services. Perl implementation.

=head1 ATTRIBUTES

=cut

has 'queues' => ( is => 'ro', isa => 'HashRef', required => 1 );

=head1 SUBROUTINES/METHODS

=head2 BUILD

Verifies queues

=cut

sub BUILD {

    my $self = shift;

    my $queue_ok      = 1;
    my $error_message = "";
    my @queue_keys    = keys %{ $self->queues };

    if ( @queue_keys == 0 ) {
        $queue_ok      = 0;
        $error_message = "There is no defined queues.";
    }

    # Verify queues

    if ( $queue_ok == 1 ) {
        for my $queue ( keys %{ $self->queues } ) {
            if ( exists $self->queues->{$queue}->{'purpose'} ) {
                if ( $self->queues->{$queue}->{'purpose'} =~ / / ) {
                    $error_message .=
                      "$queue purpose is not allowed to contain spaces. ";
                    $queue_ok = 0;
                }
            }
            else {
                $error_message .= "$queue has no purpose defined. ";
                $queue_ok = 0;
            }
        }
    }

    if ( $queue_ok == 0 ) {
        $self->_raiseException("$error_message");
    }

    return $self;

}

=head2 _testConnection

Tests connection attributes against

=cut

sub _testConnection { die "Define _testConnection() in implementation" }

=head2 _connect

Establishes connection with message broker service

=cut

sub _connect { die "Define _connect() in implementation" }

=head2 _send

Send a message through message broker connection.

=cut

sub _send { die "Define _send() in implementation" }

=head2 _receive

Receive a message from message broker connection.

=cut

sub _receive { die "Define _receive() in implementation" }

=head2 _processConnectionData

Processes connection data.

=cut

sub _processConnectionData {
    die "Define _processConnectionData() in implementation";
}

=head2 _validateQueue

Validates queue definition.

=cut

sub _validateQueue { die "Define _validateQueue() in implementation" }

=head2 _validateMessageData

Validates message data.

=cut

sub _validateMessageData {
    die "Define _validateMessageData() in implementation";
}

=head2 _raiseException

Croaks an error message
Write a log in the near future.

=cut

sub _raiseException {
    my $self          = shift;
    my $error_message = shift;

    croak $error_message;
}

=head2 send

Send a message through message broker connection.

=cut

sub validateAndSend {
    my $self      = shift;
    my $send_data = shift;

    $self->_validateMessageData($send_data);

    my $connection_data = $self->_processConnectionData($send_data);

    my $mq = $self->_connect($connection_data);

    $self->_send( $send_data, $connection_data, $mq );

    $self->_disconnect($mq);
}

=head2 receive

Receive a message from message broker connection.

=cut

sub validateAndReceive {

    my $self       = shift;
    my $queue_data = shift;

    $self->_validateQueue($queue_data);

    my $connection_data = $self->_processConnectionData($queue_data);

    my $mq = $self->_connect($connection_data);

    my $data_received = $self->_receive( $queue_data, $connection_data, $mq );

    $self->_disconnect($mq);

    return $data_received;
}

=head2 parse_hermes_config

Parses xml hermes config. Croak if config is not valid.

=cut

sub _parse_hermes_config {

    my $hermes_config = {};

    my @valid_hermes_types = ('RabbitMQ');
    my $required_hermes_fields = { 'RabbitMQ' => [ 'user', 'password' ] };
    my $required_queue_fields =
      { 'RabbitMQ' => [ 'name', 'channel', 'purpose' ] };
    my $queue_options_fields = {
        'RabbitMQ' => [
            'queue_options',   'amqp_props',
            'publish_options', 'consume_options',
            'basic_qos_options'
        ]
    };
    my $hermes_fields = {
        'RabbitMQ' => [
            'host',  'user',        'password',  'port',
            'vhost', 'channel_max', 'frame_max', 'heartbeat',
            'timeout'
        ]
    };

    my $filename = shift;

    # Validate if file exists
    croak("There is no file provided, cannot parse any config.")
      if ( !$filename );

    croak("'$filename' file does no exist, cannot parse any config.")
      unless ( -e $filename );

    # File exists check or parse XML file
    my $parser = XML::Parser->new( ErrorContext => 2, Style => 'Tree' );
    eval { $parser->parsefile($filename); };

    if ($@) {
        $@ =~ s/at \/.*?$//s;    # remove module line number
        croak "\nERROR in '$filename':\n$@\n";
    }

    my $config = XML::SimpleObject->new( $parser->parsefile($filename) );

    croak("Hermes config not found, 'hermes' key is not pressent")
      unless ( $config->child('hermes') );

    my $hermes      = $config->child("hermes");
    my $hermes_type = $hermes->child("type")->value;

    croak("Type '$hermes_type' is invalid, configuration is invalid.")
      unless ( ( grep ( /^$hermes_type$/, @valid_hermes_types ) ) );

    $hermes_config->{type} = $hermes_type;

    my $required_errors = "";

    for
      my $required_hermes_field ( @{ $required_hermes_fields->{$hermes_type} } )
    {
        if ( !$hermes->child($required_hermes_field) ) {
            $required_errors = "$required_errors $required_hermes_field,";
        }
    }

    croak(
        "The following Hermes $hermes_type field are required:$required_errors")
      unless ( !$required_errors );

    $hermes_config->{config} = {};
    $hermes_config->{config}->{queues} = {};

    for my $field ( @{ $hermes_fields->{$hermes_type} } ) {
        if ( $hermes->child($field) ) {
            $hermes_config->{config}->{$field} = $hermes->child($field)->value;
        }
    }

    for my $queue ( $hermes->child('queue') ) {
        for my $item ( @{ $required_queue_fields->{$hermes_type} } ) {
            croak "All queues have to have '$item' attirbute, invalid config."
              unless ( $queue->attribute($item) );
        }
        $hermes_config->{config}->{queues}->{ $queue->attribute('name') } = {};
        $hermes_config->{config}->{queues}->{ $queue->attribute('name') }
          ->{purpose} = $queue->attribute('purpose');
        $hermes_config->{config}->{queues}->{ $queue->attribute('name') }
          ->{channel} = $queue->attribute('channel');
        if ( $queue->children ) {
            for my $queue_child ( $queue->children ) {
                my $child_name = $queue_child->name;
                croak(
"Parameter '$child_name' is not a valid queue parameter, invalid config."
                  )
                  unless (
                    grep( /^$child_name$/,
                        @{ $queue_options_fields->{$hermes_type} } )
                  );
                $hermes_config->{config}->{queues}
                  ->{ $queue->attribute('name') }->{$child_name} = {};
                my %queue_atributes = $queue_child->attributes;
                for my $attribute ( keys %queue_atributes ) {
                    $hermes_config->{config}->{queues}
                      ->{ $queue->attribute('name') }->{$child_name}
                      ->{$attribute} = $queue_atributes{$attribute};
                }
            }
        }
    }

    return $hermes_config;
}

=head1 FACTORY

Hermes is a factory.

=cut

=head2 Daedalus::Hermes::RabbitMQ

Daedalus::Hermes::RabbitMQ - rabbitmq driver

=cut

__PACKAGE__->add_factory_type( rabbitmq => 'Daedalus::Hermes::RabbitMQ' );
__PACKAGE__->add_factory_type( hermes   => 'Daedalus::Hermes' );

=head1 AUTHOR

Álvaro Castellano Vela, C<< <alvaro.castellano.vela at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-daedalus-hermes at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Daedalus-Hermes>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Daedalus::Hermes


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Daedalus-Hermes>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Daedalus-Hermes>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Daedalus-Hermes>

=item * Search CPAN

L<http://search.cpan.org/dist/Daedalus-Hermes/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2018 Álvaro Castellano Vela.

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU GENERAL PUBLIC LICENSE Version 3.

=cut

1;    # End of Daedalus::Hermes
