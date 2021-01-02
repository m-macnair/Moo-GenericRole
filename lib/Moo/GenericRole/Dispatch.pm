# ABSTRACT : take an array or hash of $something and a key, and send to $self->$something->{$dispatch_value}
package Moo::GenericRole::Dispatch;
use Carp qw/confess /;
our $VERSION = 'v1.0.13';
##~ DIGEST : 0850483c82cb8d8929fed12b08bbd509
use Moo::Role;
with qw/Moo::GenericRole /;

sub dispatch {

	my ( $self, $dispatch_options, $dispatch_value, $param_ref ) = @_;
	my $ref = ref ($dispatch_options);
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
			confess("No idea what to do here");
		}
		unless ($method) {
			confess("Key value [$dispatch_value] is not allowed");
		}
	}
	ACTUALLYDISPATCH: {
		if ( $self->can($method) ) {
			return $self->$method($param_ref);
		} else {
			confess("method [$dispatch_value] is not implemented");
		}
	}

}
1;
