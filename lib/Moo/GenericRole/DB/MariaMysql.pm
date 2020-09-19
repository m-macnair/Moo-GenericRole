#ABSTRACT: overwrites/extensions to DB for maria/mysql
package Moo::GenericRole::DB::MariaMysql;
our $VERSION = 'v1.0.9';
##~ DIGEST : 7fc102b58e37e066b101b2508855fce7
use Moo::Role;
use Carp;
around "last_insert_id" => sub {
	my $orig = shift;
	my $self = shift;
	return $self->dbh->{mysql_insertid};
};

=head3 sub_on_db_tables
	Execute code ref on all tables, optionally with a where clause
=cut

sub sub_on_db_tables {

	my ( $self, $sub, $c ) = @_;
	use Carp::confess( "Invalid sub provided" ) unless ref( $sub ) eq 'CODE';
	my $sth = $self->query( "show tables " . $c->{show_suffix} || '' );
	while ( my $row = $sth->fetchrow_arrayref() ) {
		last unless &$sub( $row->[0], $c );
	}
	return 1;

}

sub sub_on_describe_table {

	my ( $self, $sub, $table, $c ) = @_;
	$c ||= {};
	Carp::confess( "Invalid sub provided" ) unless ref( $sub ) eq 'CODE';
	Carp::confess( "no table" ) unless $table;
	my ( $sth ) = $self->query( "describe `$table`" );
	while ( my $row = $sth->fetchrow_hashref() ) {
		last unless &$sub( $row, $c );
	}
	return 1;

}

sub check_table_for_columns {

	my ( $self, $table, $columns ) = @_;
	Carp::confess( "no table" )   unless $table;
	Carp::confess( "no columns" ) unless @{$columns};
	my $return = [];
	$self->sub_on_describe_table(
		sub {
			my ( $row ) = @_;
			for my $column_name ( @{$columns} ) {
				if ( $row->{Field} eq $column_name ) {
					push( @{$return}, $column_name );
					last;
				}
			}
			return 1;
		},
		$table
	);
	return $return; #return!

}

sub check_db_for_columns {

	my ( $self, $columns, $c ) = @_;
	my $map;
	$self->sub_on_db_tables(
		sub {
			my ( $table_name ) = @_;
			my $map->{$table_name} = $self->check_table_for_columns( $table_name, $columns );
		}
	);
	return $map;

}
1;
