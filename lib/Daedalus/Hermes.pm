package Daedalus::Hermes;

use 5.006;
use strict;
use warnings;

use Carp qw(croak);

use base qw( Class::Factory  );
use Moose;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

use Data::Dumper;

=head1 NAME

Daedalus::Hermes - The great new Daedalus::Hermes!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Service that provides communication between Daedalus Project services. Perl implementation.

=head1 ATTRIBUTES

=cut

has 'queues' => ( is => 'ro', isa => 'HashRef', required => 1 );

=head1 SUBROUTINES/METHODS

=head1 BUILD

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

    croak "$error_message" if ( $queue_ok == 0 );

}

=head1 testConnection

Tests connection attributes against

=cut

sub testConnection { die "Define testConnection() in implementation" }

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

1;    # End of Daedalus::Hermes
