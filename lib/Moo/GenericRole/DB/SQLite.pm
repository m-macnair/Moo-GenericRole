#ABSTRACT: overwrites/extensions to DB for SQLite
package Moo::GenericRole::DB::SQLite;
our $VERSION = 'v1.0.8';
##~ DIGEST : 6d94ac28ec0d1d065a27ea5cf914825c
use Moo::Role;
use Carp qw/confess/;

ACCESSORS: {
	has sqlite_dbh => (
		is      => 'rw',
		lazy    => 1,
		default => sub {
			my ( $self ) = @_;

			$self->sqlite3_connect_to_file( $self->sqlite_path() );
		}
	);

	has sqlite_path => (
		is   => 'rw',
		lazy => 1,
	);
}

sub get_dbh {

	my ( $self, $def, $opt ) = @_;
	$opt ||= {};
	confess( 'Database not provided' ) unless $def->{database};

	confess( "SQLite Database file [$def->{database}] does not exist" ) unless -e $def->{database};
	confess( "SQLite Database file [$def->{database}] is unreadable" )  unless -r $def->{database};
	confess( "SQLite Database file [$def->{database}] is unwritable" )  unless -w $def->{database};
	$opt->{AutoCommit}                 ||= 0;
	$opt->{RaiseError}                 ||= 1;
	$opt->{sqlite_see_if_its_a_number} ||= 1;

	my $dbh = DBI->connect( 'dbi:SQLite:dbname=' . $def->{database} );
	return $dbh;

}

sub last_id {
	my ( $self ) = @_;
	my $sth = $self->query( 'select last_insert_rowid()' );
	return $sth->fetchrow_arrayref()->[0];
}

sub sqlite3_connect_to_file {
	my ( $self, $path, $opt ) = @_;
	$opt ||= {};
	return $self->get_dbh( {database => $path}, $opt );
}

sub sqlite3_file_to_dbh {
	my ( $self, $path, $opt ) = @_;
	$self->sqlite_path( $path );
	$self->dbh( $self->sqlite3_connect_to_file( $path, $opt ) );

}

sub table_exists {
	my ( $self, $table_name ) = @_;
	my $sth = $self->dbh->prepare( "SELECT name FROM sqlite_master WHERE type='table' AND name=?" );

	$sth->execute( $table_name );
	my @row = $sth->fetchrow_array;

	# Clean up
	$sth->finish;

	# If a row is returned, the table exists
	return @row ? 1 : 0;

}

1;
