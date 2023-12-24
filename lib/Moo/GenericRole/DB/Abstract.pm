#ABSTRACT: use $self->dbi and sql abstract
package Moo::GenericRole::DB::Abstract;
our $VERSION = 'v2.1.2';
##~ DIGEST : fa9437a3e38ce77d34e54c22df4430f6
use Try::Tiny;
use Moo::Role;
use Carp;
with qw/Moo::GenericRole/;
ACCESSORS: {
	has sqla => (
		is      => 'rw',
		lazy    => 1,
		builder => '_build_abstract'
	);
}

sub select {

	my $self = shift;
	my ( $s, @p ) = $self->sqla->select( @_ );
	return $self->_shared_query( $s, \@p );

}

=head3 get
	Convenience wrapper around select - select($source, $fields, $where, $order)
=cut

sub get {

	my $self = shift;
	if ( ref( $_[0] ) ) {
		Carp::confess( "First parameter to SQL::Abstract must be target/source table" );
	}
	my $from = shift;
	my $sth  = $self->select( $from, ['*'], @_ );
	my $row  = $sth->fetchrow_hashref();

}

sub update {

	my $self = shift;
	if ( ref( $_[0] ) ) {
		Carp::confess( "First parameter to SQL::Abstract must be target/source table" );
	}
	my ( $s, @p ) = $self->sqla->update( @_ );
	return $self->_shared_query( $s, \@p );

}

sub insert {

	my $self = shift;
	if ( ref( $_[0] ) ) {
		Carp::confess( "First parameter to SQL::Abstract must be target/source table" );
	}
	my ( $s, @p ) = $self->sqla->insert( @_ );

	return $self->_shared_query( $s, \@p );

}

sub delete {

	my $self = shift;
	if ( ref( $_[0] ) ) {
		Carp::confess( "First parameter to SQL::Abstract must be target/source table" );
	}
	my ( $s, @p ) = $self->sqla->delete( @_ );
	return $self->_shared_query( $s, \@p );

}

sub _shared_query {

	my ( $self, $Q, $P ) = @_;
	$P ||= [];

	# 	print "$Q with" . Data::Dumper::Dumper( \@{$P} );
	my $sth;
	unless ( $sth = $self->dbh->prepare( $Q ) ) {
		Carp::confess "failed to prepare statement [$Q]";
	}
	try {
		$sth->execute( @{$P} ) or die $!;
	} catch {
		require Data::Dumper;
		Carp::confess( "Failed to execute ($Q) with parameters" . Data::Dumper::Dumper( \@{$P} ) );
	};
	return $sth;

}

sub _build_abstract {

	require SQL::Abstract;
	return SQL::Abstract->new();

}
1;
