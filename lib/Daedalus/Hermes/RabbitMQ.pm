package Daedalus::Hermes::RabbitMQ;

use 5.006;
use strict;
use warnings;

use Moose;

use base qw( Daedalus::Hermes );

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
has 'timeout' => ( is => 'ro', isa => 'Int' );

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

    # Publish options

    my @allowed_publish_boolean_options =
      ( 'mandatory', 'immediate', 'force_utf8_in_header_strings' );
    my @allowed_publish_string_options = ('exchange');
    my @allowed_publish_options =
      ( @allowed_publish_boolean_options, @allowed_publish_string_options );

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
        if ( exists $self->queues->{$queue}->{'queue_options'} ) {

            # The only queue options allowed are:
            #     passive      -> default 0
            #     durable     -> default 0
            #     exclusive   -> default 0
            #     auto_delete -> default 0
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
                        _testBooleanOption(
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
                            _testBooleanOption(
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
    }

    if ( $queue_ok == 1 ) {

        $self->_testConnection();

    }
    else {
        $self->_raiseException($error_message);
    }
}

=head2 _testBooleanOption

Tests if boolean values are correct

=cut

sub _testBooleanOption() {
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
        channel => $self->queues->{ $data->{queue} }->{channel},
        purpose => $self->queues->{ $data->{queue} }->{purpose},
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
    $mq->queue_declare( $connection_data->{channel},
        $connection_data->{purpose} );
    $mq->publish(
        $connection_data->{channel},
        $connection_data->{purpose},
        $send_data->{message}
    );

}

=head2 _receive

Receive a message from a RabbitMQ connection.

=cut

sub _receive {

    my $self            = shift;
    my $queue_data      = shift;
    my $connection_data = shift;
    my $mq              = shift;

    #$self->_validateQueue($queue_data);

    $mq->channel_open( $connection_data->{channel} );
    $mq->queue_declare( $connection_data->{channel},
        $connection_data->{purpose} );
    $mq->consume( $connection_data->{channel}, $connection_data->{purpose} );

    my $received = $mq->recv(0);

    return $received;
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
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

__PACKAGE__->meta->make_immutable;
1;    # End of Daedalus::Hermes::RabbitMQ
