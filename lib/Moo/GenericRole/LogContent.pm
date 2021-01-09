#ABSTRACT : use CGI sensibly
package Moo::GenericRole::LogContent;
our $VERSION = 'v1.0.1';
##~ DIGEST : 14851b88a77c2c0cf657b91dc6b95f97
use Moo::Role;
with qw/Moo::GenericRole/;
use Carp;

ACCESSORS: {
	has log_pip_counter => (
		is      => 'rw',
		lazy    => 1,
		default => sub {
			return 0;
		}
	);

	has log_pip_limit => (
		is      => 'rw',
		lazy    => 1,
		default => sub {
			return 80;
		}
	);
}

=head3 log_pip
	Return a '.' or a $/ depending on how many '.' went before
	Useful for 'do something that takes a while' with discernable progress points on the way - to indicate it's still going
	important to use $| = 1; during console writes
=cut

sub log_pip {

	my ( $self ) = @_;
	if ( $self->log_pip_counter >= $self->log_pip_limit ) {
		return $self->log_pip_reset();
	}
	$self->log_pip_counter( $self->log_pip_counter + 1 );
	return '.';

}

sub log_pip_reset {
	my ( $self ) = @_;

	$self->log_pip_counter( 1 );
	return $/;
}

1;
