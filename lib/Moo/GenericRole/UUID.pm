# ABSTRACT : hold a persistent UUID and create them as a method for whatever
package Moo::GenericRole::UUID;
our $VERSION = 'v1.0.12';
##~ DIGEST : 7c1d7828243904d5226bc059abc6e317

use Moo::Role;
with qw/Moo::GenericRole/;
use Data::UUID;

ACCESSORS: {
	has uuid => (
		is      => 'rw',
		lazy    => 1,
		default => sub { $_[0]->get_uuid() }
	);
}

sub getuuid {

	cluck( "Obsolete method name" );
	return get_uuid();

}

sub get_uuid {

	my $ug = Data::UUID->new;
	return lc( $ug->create_str() );

}
1;
