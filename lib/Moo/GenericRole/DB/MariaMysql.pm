#ABSTRACT: overwrites/extensions to DB for maria/mysql
package Moo::GenericRole::DB::MariaMysql;
our $VERSION = 'v1.0.11';
##~ DIGEST : bb007293382a2639622fc9eda57bf918
use Moo::Role;
use Carp;
around "last_insert_id" => sub {
	my $orig = shift;
	my $self = shift;
	return $self->dbh->{mysql_insertid};
};
ACCESSORS: {
	has mysqldump_bin => (
		is      => 'rw',
		lazy    => 1,
		default => sub { 'mysqldump' }
	);

	has mysql_cli_bin => (
		is      => 'rw',
		lazy    => 1,
		default => sub { 'mysql' }
	);

	has mysql_connect_conf => (
		is      => 'rw',
		lazy    => 1,
		default => sub { return {} }
	);
}

=head3 sub_on_db_tables
	Execute code ref on all tables, optionally with a where clause
=cut

sub sub_on_db_tables {

	my ( $self, $sub, $c ) = @_;
	$c ||= {};
	Carp::confess( "Invalid sub provided" ) unless ref( $sub ) eq 'CODE';
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
			$map->{$table_name} = $self->check_table_for_columns( $table_name, $columns );
		}
	);
	return $map;

}

sub mysql_cli_string {

	my ( $self, $args, $stack ) = @_;

	my ( $start_string, $mid_string, $end_string ) = $self->_shared_mysql_string( $args, $stack );
	$start_string = $self->mysql_cli_bin . $start_string;
	if ( wantarray() ) {
		return ( $start_string, $mid_string, $end_string );
	} else {
		return "$start_string $mid_string $end_string";
	}

}

sub mysqldump_string {

	my ( $self,         $args,       $stack )      = @_;
	my ( $start_string, $mid_string, $end_string ) = $self->_shared_mysql_string( $args, $stack );
	$start_string = $self->mysqldump_bin . $start_string;
	if ( wantarray() ) {
		return ( $start_string, $mid_string, $end_string );
	} else {
		return "$start_string $mid_string $end_string";
	}

}

sub _shared_mysql_string {
	my ( $self, $args, $stack ) = @_;

	$stack ||= [];
	my $pass_string;
	if ( $args->{pass} ) {
		$pass_string = "-p$args->{pass} ";
	}

	my $host_string = '';
	if ( $args->{host} ) {
		$host_string = "-h$args->{host} ";
	}

	my $port_string = '';
	if ( $args->{port} ) {
		$port_string = "-p$args->{port} ";
	}
	my $start_string = " -u $args->{user}\t$pass_string\t$host_string\t$port_string ";
	my $mid_string   = join( "\t", @{$stack} ) || '';
	my $table        = $args->{table} || '';
	my $end_string   = "\t$args->{db}\t$table\t";

	return ( $start_string, $mid_string, $end_string );

}
1;
