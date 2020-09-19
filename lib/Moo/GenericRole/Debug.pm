package Moo::GenericRole::Debug;
our $VERSION = 'v1.0.4';
##~ DIGEST : c4a7b60d9599e8df60b173972869ca26
use Moo::Role;
ACCESSORS: {
	has debug => (
		is      => 'rw',
		lazy    => 1,
		default => sub { return $ENV{DEBUG} }
	);
}

sub debug_msg {

	my ( $self, $msg, $min_lvl ) = @_;
	$min_lvl ||= 1;
	my $debug = $self->debug || 0;
	print "[DEBUG] $msg$/" if $debug >= $min_lvl;

}
1;
