#ABSTRACT: use $self->dbi and sql abstract
package Moo::GenericRole::DB::Abstract;
our $VERSION = 'v2.2.3';
##~ DIGEST : f62ed02775218331e4101a00c0b5e658
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

sub select_insert {
	my ( $self, $table, $field, $criteria, $opt ) = @_;
	Carp::Cluck( "Obsolete method name" );
	return $self->select_insert_href( $table, $criteria, $field, $opt );
}

sub select_insert_href {
	my ( $self, $table, $criteria, $field, $opt ) = @_;
	$field ||= [qw/*/];
	$opt   ||= {};
	my $row = $self->select( $table, $field, $criteria )->fetchrow_hashref();
	unless ( $row ) {
		$self->insert( $table, $criteria );
		$row = $self->select( $table, $field, $criteria )->fetchrow_hashref();
	}
	return $row;
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
