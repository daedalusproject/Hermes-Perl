package Daedalus::Hermes::RabbitMQ;

use 5.006;
use strict;
use warnings;

use Moose;

use base qw( Daedalus::Hermes );

use Data::Dumper;

use Moose;
use Net::AMQP::RabbitMQ;
use MooseX::StrictConstructor;

use Scalar::Util qw(looks_like_number);

use namespace::autoclean;

=head1 NAME

Daedalus::Hermes::RabbitMQ - Hermes RabbitMQ implementation.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Service that provides communication between Daedalus Project services using RabbitMQ as message broker.

    use Daedalus::Hermes::RabbitMQ;

=cut

=head1 ATTRIBUTES

=cut

has 'host' =>
  ( is => 'ro', isa => 'Str', default => "127.0.0.1", required => 1 );
has 'user'     => ( is => 'ro', isa => 'Str', required => 1 );
has 'password' => ( is => 'ro', isa => 'Str', required => 1 );
has 'port'     => ( is => 'ro', isa => 'Int', default  => 5672, required => 1 );
has 'vhost'    => ( is => 'ro', isa => 'Str', default  => "/", required => 1 );
has 'channel_max' => ( is => 'ro', isa => 'Int', default => 0, required => 1 );
has 'frame_max' =>
  ( is => 'ro', isa => 'Int', default => 131072, required => 1 );
has 'heartbeat' => ( is => 'ro', isa => 'Int', default => 0, required => 1 );
has 'timeout' => ( is => 'ro', isa => 'Int', default => 60 );

=head1 SUBROUTINES/METHODS
=cut

sub BUILD {
    my $class = shift;

    my $self = $class->SUPER::BUILD();

    my $queue_ok = 1;

    # Queue has to use a channel and channel numbers can't be repeated
    my @used_channels;

    my @allowed_queue_options =
      ( 'passive', 'durable', 'exclusive', 'auto_delete' );

    # The only queue options allowed are:
    #     passive      -> default 0
    #     durable     -> default 0
    #     exclusive   -> default 0
    #     auto_delete -> default 0
    my $default_queue_options =
      { passive => 0, durable => 0, exclusive => 0, auto_delete => 0 };

    # Publish options

    my @allowed_publish_boolean_options =
      ( 'mandatory', 'immediate', 'force_utf8_in_header_strings' );
    my @allowed_publish_string_options = ('exchange');
    my @allowed_publish_options =
      ( @allowed_publish_boolean_options, @allowed_publish_string_options );

    # AMQP 'props'
    my @allowed_amqp_integer_props =
      ( 'delivery_mode', 'priority', 'timestamp' );
    my @allowed_amqp_string_props = (
        'content_type',   'content_encoding',
        'correlation_id', 'reply_to',
        'expiration',     'message_id',
        'type',           'user_id',
        'app_id'
    );
    my @allowed_amqp_hash_props = ('headers');
    my @allowed_amqp_props      = (
        @allowed_amqp_integer_props, @allowed_amqp_string_props,
        @allowed_amqp_hash_props
    );

    # basic_qos
    my @allowed_basic_qos_integer_options =
      ( 'prefetch_count', 'prefetch_size' );
    my @allowed_basic_qos_boolean_options = ('global');
    my @allowed_basic_qos_options = ( @allowed_basic_qos_integer_options,
        @allowed_basic_qos_boolean_options );

    # Consume options
    # consumer_tag => $tag,    #absent by default
    my @allowed_consume_options =
      ( 'no_local', 'no_ack', 'props', 'consumer_tag', 'exclusive' );

    # Default consume options
    #     no_local  -> default 0
    #     no_ack    -> default 1
    #     exclusive -> default 0
    my $default_consume_options =
      { no_local => 0, no_ack => 1, exclusive => 0 };

    my $error_message = "";

    for my $queue ( keys %{ $self->queues } ) {
        if ( exists( $self->queues->{$queue}->{channel} ) ) {
            my $channel = $self->queues->{$queue}->{channel};
            if ( $channel < 1 ) {
                $queue_ok = 0;
                $error_message .= "Channel must be positive number in $queue. ";
            }
            else {
                if ( grep( /^$channel$/, @used_channels ) ) {
                    $queue_ok = 0;
                    $error_message .=
                      "There are one or more queues sharing channel $channel";
                }
                else {
                    push @used_channels, $channel;
                }
            }
        }
        else {
            $queue_ok = 0;
            $error_message .= "A channel number is required for $queue. ";
        }

        # Check queue options
        if ( exists( $self->queues->{$queue}->{'queue_options'} ) ) {

            for my $option (
                keys %{ $self->queues->{$queue}->{'queue_options'} } )
            {
                if ( !( grep ( /^$option$/, @allowed_queue_options ) ) ) {
                    $error_message .=
"Queue options are restricted, \"$option\" in not a valid option.";
                    $queue_ok = 0;
                }
                else {
                    # Options values can be 0 or 1 only
                    if (
                        _testBooleanOptionInvalid(
                            $self->queues->{$queue}->{'queue_options'}
                              ->{$option}
                        )
                      )
                    {
                        $error_message .=
"Queue options values must have boolean values, 0 or 1. \"$option\" value is invalid.";
                        $queue_ok = 0;
                    }
                }
            }
        }
        else {
            $self->queues->{$queue}->{'queue_options'} = {};
        }

        # Default Queue Options
        for my $option ( keys %{$default_queue_options} ) {
            if (
                !(
                    exists(
                        $self->queues->{$queue}->{'queue_options'}->{$option}
                    )
                )
              )
            {
                $self->queues->{$queue}->{'queue_options'}->{$option} =
                  $default_queue_options->{$option};
            }
        }

        # Publish Options
        if ( exists $self->queues->{$queue}->{'publish_options'} ) {

            # The only publish options allowed are:
            #   exchange                      -> default 'amq.direct'
            #   mandatory                    -> default 0
            #   immediate                    -> default 0
            #   force_utf8_in_header_strings -> default 0
            for my $option (
                keys %{ $self->queues->{$queue}->{'publish_options'} } )
            {
                if ( !( grep ( /^$option$/, @allowed_publish_options ) ) ) {
                    $error_message .=
"Publish options are restricted, \"$option\" in not a valid option.";
                    $queue_ok = 0;
                }
                else {
                    # Check boolean values
                    if ( grep /^$option$/, @allowed_publish_boolean_options ) {
                        if (
                            _testBooleanOptionInvalid(
                                $self->queues->{$queue}->{'publish_options'}
                                  ->{$option}
                            )
                          )
                        {
                            $error_message .=
"Some publish options values must have boolean values, 0 or 1. \"$option\" value is invalid.";
                            $queue_ok = 0;
                        }
                    }
                    else {
                        # Check string
                        if (
                            looks_like_number(
                                $self->queues->{$queue}->{'publish_options'}
                                  ->{$option}
                            )
                          )
                        {
                            $error_message .=
"\"$option\" publish option is invalid, must be a string.";
                            $queue_ok = 0;
                        }
                    }
                }
            }

        }

        # AMQP options
        #

        if ( exists $self->queues->{$queue}->{'amqp_props'} ) {
            for my $prop ( keys %{ $self->queues->{$queue}->{'amqp_props'} } ) {
                if ( !( grep ( /^$prop$/, @allowed_amqp_props ) ) ) {
                    $error_message .=
"AMQP props are restricted, \"$prop\" in not a valid prop.";
                    $queue_ok = 0;
                }
                else {
                    # Check interger values
                    if ( grep /^$prop$/, @allowed_amqp_integer_props ) {
                        if (
                            !(
                                looks_like_number(
                                    $self->queues->{$queue}->{'amqp_props'}
                                      ->{$prop}
                                )
                            )
                          )
                        {
                            $error_message .=
"Some AMQP props values must be an integer. \"$prop\" value is invalid.";
                            $queue_ok = 0;
                        }
                    }

                    # Check string values
                    elsif ( grep /^$prop$/, @allowed_amqp_string_props ) {
                        my $string_value =
                          $self->queues->{$queue}->{'amqp_props'}->{$prop};
                        unless ( $string_value & ~$string_value ) {
                            $error_message .=
"Some AMQP props values must be strings. \"$prop\" value is invalid.";
                            $queue_ok = 0;

                        }
                    }

                    # Hash
                    elsif ( grep /^$prop$/, @allowed_amqp_hash_props ) {
                        unless (
                            ref(
                                $self->queues->{$queue}->{'amqp_props'}->{$prop}
                            ) eq "HASH"
                          )
                        {
                            $error_message .=
"Some AMQP props values must be a hash. \"$prop\" value is invalid.";
                            $queue_ok = 0;
                        }
                    }
                }
            }
        }

        # basic_qos
        if ( exists $self->queues->{$queue}->{'basic_qos_options'} ) {
            for my $option (
                keys %{ $self->queues->{$queue}->{'basic_qos_options'} } )
            {

                if ( !( grep ( /^$option$/, @allowed_basic_qos_options ) ) ) {
                    $error_message .=
"Basic qos options are restricted, \"$option\" in not a valid option.";
                    $queue_ok = 0;
                }
                else {
                    if ( grep /^$option$/, @allowed_basic_qos_integer_options )
                    {
                        if (
                            !(
                                looks_like_number(
                                    $self->queues->{$queue}
                                      ->{'basic_qos_options'}->{$option}
                                )
                            )
                          )
                        {
                            $error_message .=
"Some Basic qos options must be an integer. \"$option\" value is invalid.";
                            $queue_ok = 0;
                        }
                    }
                    elsif ( grep /^$option$/,
                        @allowed_basic_qos_boolean_options )
                    {
                        if (
                            (
                                _testBooleanOptionInvalid(
                                    $self->queues->{$queue}
                                      ->{'basic_qos_options'}->{$option}
                                )
                            )
                          )
                        {
                            $error_message .=
"Some Basic qos options must have a bool value. \"$option\" value is invalid.";
                            $queue_ok = 0;
                        }

                    }

                }

            }
        }

        # consume_options
        if ( exists $self->queues->{$queue}->{consume_options} ) {
            for my $option (
                keys %{ $self->queues->{$queue}->{consume_options} } )
            {
                if ( !( grep ( /^$option$/, @allowed_consume_options ) ) ) {
                    $error_message .=
"Consume options are restricted, \"$option\" in not a valid option.";
                    $queue_ok = 0;
                }
                else {
                    if (
                        (
                            _testBooleanOptionInvalid(
                                $self->queues->{$queue}->{consume_options}
                                  ->{$option}
                            )
                        )
                      )
                    {
                        $error_message .=
"Consume options must have a bool value. \"$option\" value is invalid.";
                        $queue_ok = 0;
                    }

                }

            }

        }
        else {
            $self->queues->{$queue}->{consume_options} = {};
        }

        for my $option ( keys %{$default_consume_options} ) {
            if (
                !(
                    exists(
                        $self->queues->{$queue}->{consume_options}->{$option}
                    )
                )
              )
            {
                $self->queues->{$queue}->{consume_options}->{$option} =
                  $default_consume_options->{$option};
            }

        }

        # Default consume options

        if ( $queue_ok == 1 ) {

            $self->_testConnection();

        }
        else {
            $self->_raiseException($error_message);
        }
    }
}

=head2 _testBooleanOptionInvalid

Tests if boolean values are incorrect

=cut

sub _testBooleanOptionInvalid() {
    my $value = shift;

    return ( !( looks_like_number($value) ) || ( $value != 0 && $value != 1 ) );
}

=head2 _testConnection

Tests connection attributes against RabbitMQ server.

=cut

sub _testConnection {
    my $self = shift;

    my $mq = $self->_connect();
    $self->_disconnect($mq);
    return 1;
}

=head2 _connect

Connect against RabbitMQ server.

=cut

sub _connect {
    my $self            = shift;
    my $connection_data = shift;

    my $mq = Net::AMQP::RabbitMQ->new;

    $mq->connect(

        $self->host,
        {
            user        => $self->user,
            password    => $self->password,
            port        => $self->port,
            vhost       => $self->vhost,
            channel_max => $self->channel_max,
            heartbeat   => $self->heartbeat,
            timeout     => $self->timeout,
        }

    );

    return $mq;

}

=head2 _disconnect

Closes RabbitMQ connection.

=cut

sub _disconnect {
    my $self = shift;
    my $mq   = shift;

    $mq->disconnect;

    return 1;
}

=head2 _validateMessageData

Validates message Data.

=cut

sub _validateMessageData {

    my $self         = shift;
    my $message_data = shift;

    if ($message_data) {
        if (   exists( $message_data->{queue} )
            && exists( $message_data->{message} ) )
        {
            if ( !( exists( $self->queues->{ $message_data->{queue} } ) ) ) {
                $self->_raiseException(
"Queue $message_data->{queue} is not defined in Daedalus::Hermes::RabbitMQ configuration, cannot send any message."
                );
            }
        }
        else {
            $self->_raiseException(
"There are is no defined queue or message, cannot send any message."
            );
        }
    }
    else {
        $self->_raiseException(
            "There are is no defined data for sending any message.");
    }
}

=head2 _validateQueue

Validates Queue existence.

=cut

sub _validateQueue {

    my $self = shift;
    my $data = shift;

    if ($data) {
        if ( exists( $data->{queue} ) ) {
            if ( !( exists( $self->queues->{ $data->{queue} } ) ) ) {
                $self->_raiseException(
"Queue $data->{queue} is not defined in Daedalus::Hermes::RabbitMQ configuration, cannot connect."
                );
            }
        }
        else {
            $self->_raiseException("There are is no defined queue.");
        }
    }
    else {
        $self->_raiseException("There are is no defined data to connect.");
    }
}

=head2 _processConnectionData

Procceses RabbitMQ connection data.

=cut

sub _processConnectionData {

    my $self = shift;
    my $data = shift;

    my $connection_data = {
        channel         => $self->queues->{ $data->{queue} }->{channel},
        purpose         => $self->queues->{ $data->{queue} }->{purpose},
        queue_options   => $self->queues->{ $data->{queue} }->{queue_options},
        publish_options => $self->queues->{ $data->{queue} }->{publish_options},
        amqp_props      => $self->queues->{ $data->{queue} }->{amqp_props},
        basic_qos_options =>
          $self->queues->{ $data->{queue} }->{basic_qos_options},
        consume_options => $self->queues->{ $data->{queue} }->{consume_options},
    };

    # Check extra options

    return $connection_data;

}

=head2 _send

Send a message through a RabbitMQ connection.

=cut

sub _send {

    my $self            = shift;
    my $send_data       = shift;
    my $connection_data = shift;
    my $mq              = shift;

    $mq->channel_open( $connection_data->{channel} );

    # Queue Declare

    my $channel       = $connection_data->{channel};
    my $purpose       = $connection_data->{purpose};
    my $queue_options = $connection_data->{queue_options};

    $mq->queue_declare( $channel, $purpose, $queue_options );

    # Publish

    my $message         = $send_data->{message};
    my $publish_options = undef;
    if ( $connection_data->{publish_options} ) {
        $publish_options = $connection_data->{publish_options};
    }
    my $amqp_props = {};
    if ( $connection_data->{amqp_props} ) {
        $amqp_props = $connection_data->{amqp_props};
    }

    $mq->publish( $channel, $purpose, $message, $publish_options, $amqp_props );
}

=head2 _receive

Receive a message from a RabbitMQ connection.

=cut

sub _receive {

    my $self            = shift;
    my $queue_data      = shift;
    my $connection_data = shift;
    my $mq              = shift;

    $mq->channel_open( $connection_data->{channel} );

    # Queue Declare

    my $channel           = $connection_data->{channel};
    my $purpose           = $connection_data->{purpose};
    my $queue_options     = $connection_data->{queue_options};
    my $basic_qos_options = {};
    my $consume_options   = {};

    if ( $connection_data->{consume_options} ) {
        $consume_options = $connection_data->{consume_options};
    }

    if ( $connection_data->{basic_qos_options} ) {
        $basic_qos_options = $connection_data->{basic_qos_options};
    }

    $mq->queue_declare( $channel, $purpose, $queue_options );

    $mq->consume( $channel, $purpose, $consume_options );

    my $received = $mq->recv(0);

    if ( $consume_options->{no_ack} eq '0' ) {
        $mq->ack( $channel, $received->{delivery_tag} );
    }

    return $received;
}

=head2 sendACK

Sends ACK

=cut

sub sendACK {
    my $self          = shift;
    my $queue_data    = shift;
    my $received_data = shift;

    $self->_validateQueue($queue_data);

    my $connection_data = $self->_processConnectionData($queue_data);

    my $channel = $connection_data->{channel};

    if ( $connection_data->{consume_options}->{no_ack} == 1 ) {
        $self->_raiseException(
"This queue sends ACK messages automatically, it is not possible to send ACK message again."
        );
    }

    my $mq = $self->_connect($connection_data);

    $mq->ack( $channel, $received_data->{delivery_tag} );

    $self->_disconnect($mq);
}

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

__PACKAGE__->meta->make_immutable;
1;    # End of Daedalus::Hermes::RabbitMQ
