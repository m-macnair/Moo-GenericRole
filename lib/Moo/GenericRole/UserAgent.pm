#ABSTRACT: send & recieve HTTP requests of various formats
package Moo::GenericRole::UserAgent;
our $VERSION = 'v1.0.12';
##~ DIGEST : 2bf0d3bf95cf8e4d5f63954bb7163d4c

use Moo::Role;
with qw/Moo::GenericRole/;
ACCESSORS: {
	has defaulttimeout => (
		is      => 'rw',
		lazy    => 1,
		default => sub { return 1000 }
	);
}

after new => sub {
	my ( $self ) = @_;
# 	$self->_verify_methods( [qw/json /] );
};

#send json from a href and return the response object
sub post_json {

	my ( $self, $url, $q, $p ) = @_;
	$p ||= {};
	my $ua = $self->get_lwp_user_agent();
	$ua->timeout( $p->{defaulttimeout} || $self->defaulttimeout() );
	require HTTP::Request;
	my $req = HTTP::Request->new( 'POST', $url );
	$req->header( 'Content-Type' => 'application/json' );
	$req->content( $self->json->encode( $q ) );
	my $result = $ua->request( $req );
	return $result;

}

#send arbitrary data 
sub post_misc {

	my ( $self, $url, $data, $p ) = @_;
	Carp::confess("Invalid \$data structure supplied - must be a href") unless ref($data) eq 'HASH';
	$self->demand_params($p,[qw/Content-Type/]);
	
	my $ua = $self->get_lwp_user_agent();
	$ua->timeout( $p->{defaulttimeout} || $self->defaulttimeout() );
	return $ua->post( $url, $data ); 

}

#as above but interpret the result as JSON as well
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



sub get_lwp_user_agent {

	require LWP::UserAgent;
	return LWP::UserAgent->new();

}

sub lwpuseragent {

	warn "obsolete naming";
	get_lwp_user_agent();

}

1;
