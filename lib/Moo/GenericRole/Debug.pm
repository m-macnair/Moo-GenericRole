package Moo::GenericRole::Debug;
our $VERSION = 'v1.0.2';

##~ DIGEST : 0c2fac68a3d1ed7a6f5cf2525b59a982
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
