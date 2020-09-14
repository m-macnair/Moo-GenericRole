package Moo::GenericRole::DB::Abstract;
our $VERSION = 'v1.0.3';

##~ DIGEST : c5289c6205c48acf2b735727da874f45
#ABSTRACT: use $self->dbi and sql abstract
use Try::Tiny;
use Moo::Role;

ACCESSORS: {

    has sqla => (
        is      => 'rw',
        lazy    => 1,
        builder => '_build_abstract'
    );

}

sub select {
    my $self = shift;
    my ( $s, @p ) = $self->sqla->select(@_);
    return $self->_shared_query( $s, \@p );
}

=head3 get
	Convenience wrapper around select
=cut

sub get {
    my $self = shift;
    my $from = shift;
    my $sth  = $self->select( $from, ['*'], @_ );
    my $row  = $sth->fetchrow_hashref();
}

sub update {
    my $self = shift;
    my ( $s, @p ) = $self->sqla->update(@_);
    return $self->_shared_query( $s, \@p );
}

sub insert {
    my $self = shift;
    my ( $s, @p ) = $self->sqla->insert(@_);
    return $self->_shared_query( $s, \@p );
}

sub delete {
    my $self = shift;
    my ( $s, @p ) = $self->sqla->delete(@_);
    return $self->_shared_query( $s, \@p );

}

sub _shared_query {
    my ( $self, $Q, $P ) = @_;
    $P ||= [];
    print "$Q with" . Data::Dumper::Dumper( \@{$P} );
    my $sth = $self->dbh->prepare($Q) or die "failed to prepare statement :/";

    try {
        $sth->execute( @{$P} ) or die $!;
    }
    catch {
        require Data::Dumper;
        require Carp;
        Carp::confess( "Failed to execute ($Q) with parameters"
              . Data::Dumper::Dumper( \@{$P} ) );
    };
    return $sth;

}

sub _build_abstract {
    require SQL::Abstract;
    return SQL::Abstract->new();
}

1;
