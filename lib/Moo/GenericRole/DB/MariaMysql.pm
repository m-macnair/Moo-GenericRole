#ABSTRACT: overwrites/extensions to DB for maria/mysql
package Moo::GenericRole::DB::MariaMysql;
our $VERSION = 'v1.0.18';
##~ DIGEST : a7b008e83fa51bc49feacd0d91e2d223
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
	has mysql_table_exists_sth => (
		is      => 'rw',
		lazy    => 1,
		default => sub { my ( $self ) = @_; return $self->dbh->prepare( "SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = ?" ); }
	);
}

=head3 sub_on_database
	when given a href def, set $self->dbh to said dbh; then do some sub

=cut

sub sub_on_database {

	my ( $self, $sub, $def ) = @_;
	Carp::confess( "Invalid sub provided" ) unless ref( $sub ) eq 'CODE';

	#this will be different in other sqls
	$self->demand_params(
		$def,
		[
			qw/
			  host
			  user
			  pass
			  driver
			  /
		]
	);
	$self->set_dbh_from_def( $def );
	&$sub();

}

=head3 sub_on_db_tables
	Execute code ref on all tables, optionally with a where clause
=cut

sub sub_on_db_tables {

	my ( $self, $sub, $c ) = @_;
	$c ||= {};
	Carp::confess( "Invalid sub provided" ) unless ref( $sub ) eq 'CODE';
	my $sth = $self->query( "show tables " . ( $c->{show_suffix} || '' ) );
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

sub sub_on_show_table_index {

	my ( $self, $sub, $table, $c ) = @_;
	$c ||= {};
	Carp::confess( "Invalid sub provided" ) unless ref( $sub ) eq 'CODE';
	Carp::confess( "no table" ) unless $table;
	my ( $sth ) = $self->query( "show index from `$table`" );
	while ( my $row = $sth->fetchrow_hashref() ) {
		last unless &$sub( $row, $c );
	}
	return 1;

}

sub check_table_for_columns {

	my ( $self, $table, $columns, $c ) = @_;
	$c ||= {};
	Carp::confess( "no table" )   unless $table;
	Carp::confess( "no columns" ) unless @{$columns};
	my $return = [];
	$self->sub_on_describe_table(
		sub {
			my ( $row ) = @_;
			for my $column_name ( @{$columns} ) {
				if ( $row->{Field} eq $column_name ) {
					push( @{$return}, $column_name );
					last if ( @{$return} == @{$columns} );
				}
			}
			return 1;
		},
		$table
	);
	if ( $c->{force_exact} ) {
		if ( @{$return} == @{$columns} ) {
			return $return;
		} else {
			return [];
		}
	}
	return $return; #return!

}

sub check_db_for_columns {

	my ( $self, $columns, $c ) = @_;
	my $map;
	$self->sub_on_db_tables(
		sub {
			my ( $table_name ) = @_;
			$map->{$table_name} = $self->check_table_for_columns( $table_name, $columns, $c );
		}
	);
	return $map;

}

sub mysql_cli_string {

	my ( $self,         $args,       $stack )      = @_;
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
	$start_string = $self->mysqldump_bin . " $start_string";
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
	if ( $args->{pass} || $args->{password} ) {
		$pass_string = "-p'" . ( $args->{pass} || $args->{password} ) . "' ";
	}
	my $host_string = '';
	if ( $args->{host} ) {
		$host_string = "-h$args->{host} ";
	}
	my $port_string = '';
	if ( $args->{port} ) {
		$port_string = "-P $args->{port} ";
	}
	my $start_string = " -u $args->{user}\t$pass_string\t$host_string\t$port_string ";
	my $mid_string   = join( "\t", @{$stack} ) || '';
	my $table        = $args->{table} || '';
	my $db           = $args->{db} || $args->{database};
	my $end_string   = "\t$db\t$table\t";
	return ( $start_string, $mid_string, $end_string );

}

sub table_exists {
	my ( $self, $table_name ) = @_;

	$self->mysql_table_exists_sth->execute( $table_name );
	return $self->mysql_table_exists_sth->fetchrow_arrayref();
}
1;
