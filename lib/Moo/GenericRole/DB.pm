package Moo::GenericRole::DB;
our $VERSION = 'v1.0.9';
##~ DIGEST : 34745dbdb4bd71e8f1566bc70e4e0328
use Moo::Role;
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

sub query {

	my $self = shift();

	#HOURS wasted because I didn't know this was a thing
	my $sth = $self->prepare_cached( shift );
	$sth->execute( @_ );
	return $sth;

}

sub _set_dbh {

	my $self = shift;
	use DBI;
	my $dbh = DBI->connect( @_ ) or die $DBI::errstr;
	$self->dbh( $dbh );
	return 1;

}

sub commitmaybe {

	my ( $self ) = @_;
	my $counter = $self->_transaction_counter();
	$counter++;
	if ( $counter >= $self->_statement_limit() ) {
		$self->dbh->commit() unless $self->dbh->{AutoCommit};
		$counter = 0;
	}
	$self->_transaction_counter( $counter );

}

sub commithard {

	my ( $self ) = @_;
	$self->_transaction_counter( 0 );
	$self->dbh->commit() unless $self->dbh->{AutoCommit};

}

sub get_column_hash {

	my ( $self, $sth, $col ) = @_;
	my $return = [];
	Carp::confess( "Column not provided and cannot be inferred" ) unless $col;
	while ( my $row = $sth->fetchrow_hashref() ) {
		push( @{$return}, $row->{$col} );
	}
	return $return;

}

sub get_column_array {

	my ( $self, $sth, $col ) = @_;
	my $return = [];
	$col ||= 0;
	while ( my $row = $sth->fetchrow_arrayref() ) {
		push( @{$return}, $row->[$col] );
	}
	return $return;

}

sub last_insert_id {

	die "nope";

}
1;
