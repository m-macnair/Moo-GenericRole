# ABSTRACT : use MCE::Shared intelligently
use strict;

package Moo::GenericRole::MCEShared;

our $VERSION = 'v1.0.3';
##~ DIGEST : 02315e89aaeb547f1e40f26eafe2aab2

use Moo::Role;
use 5.006;
use warnings;

use MCE::Shared;

=head1 NAME
	~
=head1 VERSION & HISTORY
	<breaking revision>.<feature>.<patch>
	1.0.0 - <date>
		<actions>
	1.0.0 - <date unless same as above>
		The Mk1
=cut

=head1 SYNOPSIS
	TODO
=head2 TODO
	Generall planned work
=head1 ACCESSORS
=cut

ACCESSORS: {

	has pid_stack => (
		is      => 'rw',
		lazy    => 1,
		default => sub { return [] }
	);
}

=head1 SUBROUTINES/METHODS
=head2 PRIMARY SUBS
	Main purpose of the module
=head3 poe_method
	Execute a method in its own child thread
=cut

sub forked_method {
	my ( $self, $method, $params ) = @_;
	my $pid = fork;
	die "failed to fork: $!" unless defined $pid;
	push( @{$self->pid_stack}, $pid );
	if ( $pid == 0 ) {
		$self->$method( @{$params} );
		exit;
	}

	return $pid;

}

=head3 prefork_share_accessors
	Enable accessors to be accessed between children 
=cut

sub prefork_share_accessors {
	my ( $self, $aref ) = @_;

	#todo, figure out if 'all of them but intelligently' is valid

	for my $accessor ( @{$aref} ) {
		my $value = $self->$accessor();
		if ( ref( $value ) eq 'HASH' ) {

			$self->$accessor( MCE::Shared->hash( %{$value} ) );
		} elsif ( ref( $value ) eq 'ARRAY' ) {

			$self->$accessor( MCE::Shared->ARRAY( @{$value} ) );
		}
	}

}

=head1 AUTHOR
	mmacnair, C<< <mmacnair at cpan.org> >>
=head1 BUGS
	TODO Bugs
=head1 SUPPORT
	TODO Support
=head1 ACKNOWLEDGEMENTS
	TODO
=head1 COPYRIGHT
 	Copyright 2021 mmacnair.
=head1 LICENSE
	TODO
=cut

1;
