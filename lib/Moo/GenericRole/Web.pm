package Moo::GenericRole::Web;
our $VERSION = 'v1.0.4';
##~ DIGEST : 7e584713201edbfae7553de05f875c7a
use Moo::Role;
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
