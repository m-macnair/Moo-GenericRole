# ABSTRACT : Universal include for all elements in the name space
package Moo::GenericRole;
our $VERSION = 'v1.0.8';
##~ DIGEST : 72da56541baab29693fbc09f7399861e
use Moo::Role;

#because I use confess everywhere
use Carp qw(cluck confess);

ACCESSORS: {
	has verbose => (
		is      => 'rw',
		lazy    => 1,
		default => sub { return 0 }
	);

}

=head3 _verify_methods
	For use in child classes that make use of methods/accessors in other classes 
=cut

sub _verify_methods {
	my ( $self, $methods ) = @_;
	confess( "Invalid methods attribute provided" ) unless ref( $methods ) eq 'ARRAY';
	for my $method ( @{$methods} ) {
		confess( "Method $method not supported by final object" ) unless $self->can( $method );
	}
	return 1;
}

1;
