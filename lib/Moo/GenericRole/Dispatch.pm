package Moo::GenericRole::Dispatch;

# ABSTRACT : take an array or hash of $something and a key, and send to $self->$something->{$key}
use Carp qw/confess /;
our $VERSION = 'v1.0.3';

##~ DIGEST : c2b63809375235ee136deb0a80e5caff
use Moo::Role;

sub dispatch {
	my ( $self, $opt, $key ) = @_;
	my $ref = ref( $opt );
	my $method;
	DETECTMETHOD: {
		if ( $ref eq 'HASH' ) {
			$method = $opt->{$key};
		} elsif ( $ref eq 'ARRAY' ) {

			#it's assumed the most common will be at the top
			for ( @{$opt} ) {
				if ( $key eq $_ ) {
					$method = $_;
					last;
				}
			}
		} else {
			confess( "No idea what to do here" );
		}
		unless ( $method ) {
			confess( "Key value [$key] is not allowed" );
		}
	}

	ACTUALLYDISPATCH: {
		if ( $self->can( $method ) ) {
			return $self->$method();
		} else {
			confess( "method [$key] is not implemented" );
		}
	}

}
1;
