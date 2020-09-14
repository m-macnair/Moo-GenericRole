package Moo::GenericRole::Web;
our $VERSION = 'v1.0.1';

##~ DIGEST : 6d70a9bd8ff12a536922df0721496906
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
    my ($self) = @_;

    # 	warn $self->cgi->param('POSTDATA');Z
    my $req_data = $self->json->decode( $self->cgi->param('POSTDATA') );
    $req_data->{yes} = 'no';
    return $self->json->encode($req_data);

}

1;
