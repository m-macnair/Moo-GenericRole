package Moo::GenericRole::UserAgent;
our $VERSION = 'v1.0.9';
##~ DIGEST : 6a6f3275020c328a426e63bfad71544d
# Do http requests
use Moo::Role;
ACCESSORS: {
	has defaulttimeout => (
		is      => 'rw',
		lazy    => 1,
		default => sub { return 1000 }
	);
}

sub post_json {

	my ( $self, $url, $q, $p ) = @_;
	$p ||= {};
	my $ua = $self->lwp_user_agent();
	$ua->timeout( $p->{defaulttimeout} || $self->defaulttimeout() );
	require HTTP::Request;
	my $req = HTTP::Request->new( 'POST', $url );
	$req->header( 'Content-Type' => 'application/json' );
	$req->content( $self->json->encode( $q ) );
	my $result = $ua->request( $req );
	return $result;

}

sub lwp_user_agent {

	require LWP::UserAgent;
	return LWP::UserAgent->new();

}

sub lwpuseragent {

	warn "obsolete naming";
	lwp_user_agent();

}

sub post_retrieve_json {

	my ( $self, $url, $q ) = @_;
	my $response = $self->post_json( $url, $q );
	if ( $response->is_success ) {
		try {
			# 			die $response->decoded_content;
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
