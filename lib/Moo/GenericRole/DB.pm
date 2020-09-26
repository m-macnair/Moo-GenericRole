#ABSTRACT: Baseline for accessor based database interaction
package Moo::GenericRole::DB;
our $VERSION = 'v1.0.12';
##~ DIGEST : 9258d0f7873da1fd3c6b6a690befedc0
use Moo::Role;
with qw/Moo::GenericRole/;
use Carp;
ACCESSORS: {
	has dbh => (
		is      => 'rw',
		lazy    => 1,
		default => sub {
			my $self = shift;

			#this will intentionally fail on init; but the structure will be universal
			return $self->_set_dbh();
		}
	);
	has _transaction_counter => (
		is      => 'rw',
		lazy    => 1,
		default => sub { my $self = shift; return $self->_set_dbh() }
	);
	has _statement_limit => (
		is      => 'rw',
		lazy    => 1,
		default => sub { return 1000 }
	);
}

sub _set_dbh {

	my $self = shift;
	use DBI;
	my $dbh = DBI->connect( @_ ) or die $DBI::errstr;
	$self->dbh( $dbh );
	return 1;

}

# prepare, execute and return sth
sub query {

	my $self = shift();

	#HOURS wasted because I didn't know this was a thing
	my $sth = $self->dbh->prepare_cached( shift );
	$sth->execute( @_ );
	return $sth;

}

sub commit_maybe {

	my ( $self ) = @_;
	my $counter = $self->_transaction_counter();
	$counter++;
	if ( $counter >= $self->_statement_limit() ) {
		$self->dbh->commit() unless $self->dbh->{AutoCommit};
		$counter = 0;
	}
	$self->_transaction_counter( $counter );

}

sub commit_force {

	my ( $self ) = @_;
	$self->_transaction_counter( 0 );
	$self->dbh->commit() unless $self->dbh->{AutoCommit};

}

# get all column entries as an arref
sub get_column_hash {

	my ( $self, $sth, $col ) = @_;
	my $return = [];
	Carp::confess( "Column not provided and cannot be inferred" ) unless $col;
	while ( my $row = $sth->fetchrow_hashref() ) {
		push( @{$return}, $row->{$col} );
	}
	return $return;

}

#get all column entries as an arref
sub get_column_array {

	my ( $self, $sth, $col ) = @_;
	my $return = [];
	$col ||= 0;
	while ( my $row = $sth->fetchrow_arrayref() ) {
		push( @{$return}, $row->[$col] );
	}
	return $return;

}

#placeholder to be replaced in DB specific modules - DBI's native version is not 100% reliable
sub last_insert_id {

	die "nope";

}
1;
