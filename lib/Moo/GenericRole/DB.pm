#ABSTRACT: Baseline for accessor based database interaction
package Moo::GenericRole::DB;
our $VERSION = 'v1.0.21';
##~ DIGEST : f926949d854befa0fb4c15c8b3a71701

use Moo::Role;
with qw/Moo::GenericRole/;
use Carp;
ACCESSORS: {
	has dbh => (
		is      => 'rw',
		lazy    => 1,
		default => sub {
			my $self = shift;
			return $self->_set_dbh();
		}
	);

	has _transaction_counter => (
		is      => 'rw',
		lazy    => 1,
		default => sub { return 0; }
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

=head3 sub_on_database_by_json_file
	Load connection details from a json string and do something - useful for loops

=cut

sub sub_on_database_by_json_file {

	my ( $self, $sub, $path, $extra ) = @_;
	$extra ||= {};
	my $def = $self->json_load_file( $path );
	$def = {%{$def}, %{$extra}};
	$self->sub_on_database( $sub, $def );

}

=head3 dbh_from_def
	From arbitrary href, do the $right thing to create a dbh
=cut

sub dbh_from_def {

	my ( $self, $def, $opt ) = @_;

	#'do what I meant'
	my $replacements = {
		db   => 'database',
		pass => 'password',
	};
	for my $key ( keys( %{$replacements} ) ) {
		if ( $def->{$key} ) {
			$def->{$replacements->{$key}} = $def->{$key};
		}
	}
	$def->{database} ||= '';
	$self->demand_params(
		$def,
		[
			qw/
			  driver
			  /
		]
	);
	my $dsn = "DBI:$def->{driver}:$def->{database};";
	for ( qw/ host port / ) {
		$dsn .= "$_=" . ( defined( $def->{$_} ) ? "$def->{$_};" : ";" );
	}
	my $dbh = DBI->connect( $dsn, $def->{user}, $def->{password}, $opt ) or die $DBI::errstr;
	return $dbh;

}

sub set_dbh_from_def {

	my ( $self, $def, $opt ) = @_;
	my $dbh = $self->dbh_from_def( $def, $opt );
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

sub execute_file {
	my ( $self, $schema_file ) = @_;

	# Open the schema file
	open my $fh, '<', $schema_file or Carp::Confess( "Cannot open schema file: $!" );

	# Read the entire schema file content
	my $schema = do { local $/; <$fh> };

	# Execute each statement in the schema file
	for my $statement ( split /;/, $schema ) {

		# Trim whitespace from each statement
		$statement =~ s/^\s+|\s+$//g;
		next if $statement eq ''; # Skip empty statements
		$self->dbh->do( $statement ) or Carp::confess( $DBI::errstr );
	}

	# Close the schema file
	close $fh;
	$self->commit_force();

}

#placeholder to be replaced in DB specific modules - DBI's native version is not 100% reliable
sub last_insert_id {

	die "nope";

}
1;
