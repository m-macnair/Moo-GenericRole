package Moo::GenericRole::Dispatch;

# ABSTRACT : take an array or hash of $something and a key, and send to $self->$something->{$dispatch_value}
use Carp qw/confess /;
our $VERSION = 'v1.0.9';
##~ DIGEST : b6b4060837f125118a3519caa6e9ff4c
use Moo::Role;

sub dispatch {

	my ( $self, $dispatch_options, $dispatch_value, $param_ref ) = @_;
	my $ref = ref( $dispatch_options );
	my $method;
	DETECTMETHOD: {
		if ( $ref eq 'HASH' ) {
			$method = $dispatch_options->{$dispatch_value};
		} elsif ( $ref eq 'ARRAY' ) {

			#it's assumed the most common will be at the top
			for ( @{$dispatch_options} ) {
				if ( $dispatch_value eq $_ ) {
					$method = $_;
					last;
				}
			}
		} else {
			confess( "No idea what to do here" );
		}
		unless ( $method ) {
			confess( "Key value [$dispatch_value] is not allowed" );
		}
	}
	ACTUALLYDISPATCH: {
		if ( $self->can( $method ) ) {
			return $self->$method( $param_ref );
		} else {
			confess( "method [$dispatch_value] is not implemented" );
		}
	}

}
1;
