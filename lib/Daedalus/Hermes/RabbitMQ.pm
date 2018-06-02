package Daedalus::Hermes::RabbitMQ;

use 5.006;
use strict;
use warnings;

use Moose;

use base qw( Daedalus::Hermes );

use Moose;
use Net::AMQP::RabbitMQ;
use MooseX::StrictConstructor;
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

=head1 SUBROUTINES/METHODS
=cut

sub BUILD {
    my $self = shift;

    my $mq = Net::AMQP::RabbitMQ->new;

    $self->_testConnection($mq);
}

=head1 testConnection

Tests connection attributes against RabbitMQ server.

=cut

sub _testConnection {
    my $self = shift;
    my $mq   = shift;

    $mq->connect(
        $self->host,
        {
            user     => $self->user,
            password => $self->password,
            port     => $self->port
        }
    );
    $mq->disconnect;
    return 1;
}

=head1 _connect

Connect against RabbitMQ server.

=cut

#sub _connect {
#
#}

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
