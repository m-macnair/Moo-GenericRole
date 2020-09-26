#ABSTRACT : use CGI sensibly
package Moo::GenericRole::Web;
our $VERSION = 'v1.0.7';
##~ DIGEST : 279ab5614134c52e781ca4ae6579ee3f
use Moo::Role;
with qw/Moo::GenericRole/;
use Carp;
ACCESSORS: {
	has cgi => (
		is      => 'rw',
		lazy    => 1,
		default => sub {
			use CGI;
			$CGI::POST_MAX = 1024 * 1024 * 10;
			return CGI::new();
		}
	);
}

sub json_req {

	my ( $self ) = @_;

	# 	warn $self->cgi->param('POSTDATA');Z
	my $req_data = $self->json->decode( $self->cgi->param( 'POSTDATA' ) );
	return $self->json->encode( $req_data );

}
1;
