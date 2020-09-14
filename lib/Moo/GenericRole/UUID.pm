package Moo::GenericRole::UUID;

# ABSTRACT : hold a persistent UUID and create them as a method for whatever
use Moo::Role;
use Data::UUID;
our $VERSION = 'v1.0.4';

##~ DIGEST : f41449bc1a981e73cdab0dc001dea693

ACCESSORS: {
    has uuid => (
        is      => 'rw',
        lazy    => 1,
        default => sub { $_[0]->get_uuid() }
    );
}

sub getuuid {
    require Carp;
    Carp::cluck("use get_uuid instead pls");
    return get_uuid();
}

sub get_uuid {
    my $ug = Data::UUID->new;
    return lc( $ug->create_str() );
}

1;
