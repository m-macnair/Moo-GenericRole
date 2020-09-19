# ABSTRACT : perform and preserve command line interaction
package Moo::GenericRole::CombinedCLI;
our $VERSION = 'v1.0.4';
##~ DIGEST : f405e47e67852188f6147a2128578656
use Moo::Role;
ACCESSORS: {
	has cfg => (
		is   => 'rw',
		lazy => 1,
	);
}

sub get_config {

	my $self = shift;
	require Toolbox::CombinedCLI;
	my $cfg = Toolbox::CombinedCLI::get_config( @_ );
	$self->cfg( $cfg );
	return $cfg;

}

#hit the default or explicit config with checks - useful when checks change after some condition
sub check_cfg {

	my ( $self, $required, $href ) = @_;
	$href ||= $self->cfg();
	require Toolbox::CombinedCLI;
	Toolbox::CombinedCLI::check_config( $href, $required );

}
1;
