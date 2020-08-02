package Moo::GenericRole::UserAgent;
our $VERSION = 'v1.0.3';

##~ DIGEST : 856f90447f170a6c60b7e1a544fc7b98
# Do http requests
use Moo::Role;

ACCESSORS: {
	has defaulttimeout => (
		is      => 'rw',
		lazy    => 1,
		default => sub { return 1000 }
	);
}

sub postjson {

	my ( $self, $url, $q, $p ) = @_;
	$p ||= {};
	my $ua = $self->lwpuseragent();
	$ua->timeout( $p->{defaulttimeout} || $self->timeout() );
	require HTTP::Request;
	my $req = HTTP::Request->new( 'POST', $url );
	$req->header( 'Content-Type' => 'application/json' );
	$req->content( $self->json->encode( $q ) );
	my $result = $ua->request( $req );
	return $result;

}

sub lwpuseragent {
	require LWP::UserAgent;
	return LWP::UserAgent->new();

}

sub postretrievejson {

	my ( $self, $url, $q ) = @_;
	my $response = $self->postjson( $url, $q );
	if ( $response->is_success ) {
		try {
			my $jsondef = $self->json->decode( $response->decoded_content );
			return {
				pass => 'data',
				data => $jsondef
			}
		} catch {
			return {fail => "JSON decoding failure : $_"};
		};
	} else {
		return {fail => $response->status_line};
	}

}

1;
