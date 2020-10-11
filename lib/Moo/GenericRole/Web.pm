#ABSTRACT : use CGI sensibly
package Moo::GenericRole::Web;
our $VERSION = 'v1.1.1';
##~ DIGEST : 886138a7764319f904359be30fcefd4c
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

sub sub_as_json_api {
	my ( $self, $sub, $input ) = @_;
	$input ||= $self->cgi->param( 'POSTDATA' );

	# 	die $input;
	my $response_struct;
	if ( $input ) {
		my $req_struct = $self->json->decode( $input );

		#try/catch
		$response_struct = &$sub( $req_struct );
		warn ref( $response_struct );
		if ( ref( $response_struct ) eq 'HASH' ) {

			#de nada
			warn "all good";
		} else {
			$response_struct = {fail => 'unhandled error',};
		}
	} else {
		$response_struct = {fail => 'empty request'};
	}
	use Data::Dumper;
	warn "restruct : " . Dumper( $response_struct );

	#try/catch
	my $response_string = $self->json->encode( $response_struct );

	print $self->cgi->header();
	print $response_string;

}

1;
