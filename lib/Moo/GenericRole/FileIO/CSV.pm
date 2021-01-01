#ABSTRACT : Do common things with CSV files
package Moo::GenericRole::FileIO::CSV;
use strict;
use warnings;
our $VERSION = 'v1.0.6';
##~ DIGEST : b2b4d31a47ee50c106a0e517a50cb751
use Moo::Role;
ACCESSORS: {
	has csv => (
		is      => 'rw',
		lazy    => 1,
		default => sub {
			_get_csv();
		}
	);

	#persistent mapping for the column position of a given file path
	has _path_column_header_orders => (
		is      => 'rw',
		lazy    => 1,
		default => sub {
			{};
		}
	);

	#we may want straight dumps sometimes
	has print_headers => (
		is      => 'rw',
		lazy    => 1,
		default => sub {
			1;
		}
	);

	#keys in order that should go first in output csv files
	has lead_keys => (
		is      => 'rw',
		lazy    => 1,
		default => sub {
			[];
		}
	);
}

# do something on csv rows that aren't commented out until something returns falsey
sub sub_on_csv {

	my ( $self, $sub, $path ) = @_;
	die "[$path] not found" unless ( -e $path );
	die "sub isn't a code reference" unless ( ref( $sub ) eq 'CODE' );
	open( my $ifh, "<:encoding(UTF-8)", $path )
	  or die "Failed to open [$path] : $!";
	my $csv = $self->csv();
	while ( my $colref = $csv->getline( $ifh ) ) {
		if ( index( $colref->[0], '#' ) == 0 ) {
			next;
		}
		last unless &$sub( $colref );
	}
	close( $ifh ) or die "Failed to close [$path] : $!";

}

sub get_csv_column {
	my ( $self, $path, $column ) = @_;
	$self->check_file( $path );
	$column ||= 0;
	my $return;
	$self->sub_on_csv(
		sub {
			my ( $row ) = @_;
			if ( $row->[$column] ) {
				push( @{$return}, $row->{$column} );
			}
		},
		$path
	);
	return $return;
}

#given a row and a path, do the right thing
sub aref_to_csv {

	my ( $self, $row, $path ) = @_;
	$self->csv->print( $self->ofh( $path ), $row );

}

#given a href and a path, do the right thing
sub href_to_csv {

	my ( $self, $row, $path ) = @_;

	my $column_order = $self->_path_column_header_orders->{$path} || $self->_init_path_columns( $row, $path );
	$self->csv->print( $self->ofh( $path ), [ @{$row}{@{$column_order}} ] );

}

#given an sth and a path, do the right thing with headers (slower)
sub sth_href_to_csv {

	my ( $self, $sth, $path ) = @_;
	while ( my $row = $sth->fetchrow_hashref() ) {
		$self->href_to_csv( $row, $path );
	}

}

sub sth_aref_to_csv {

	my ( $self, $sth, $path ) = @_;
	while ( my $row = $sth->fetchrow_arrayref() ) {
		$self->aref_to_csv( $row, $path );
	}

}

sub _init_path_columns {

	my ( $self, $p, $path ) = @_;
	if ( ref( $p ) eq 'HASH' ) {
		$self->_path_column_header_orders->{$path} = $self->_get_column_order_for_href( $p );
	} elsif ( ref( $p ) eq 'ARRAY' ) {
		$self->_path_column_header_orders->{$path} = $p;
	}
	$self->aref_to_csv( $self->_path_column_header_orders->{$path}, $path ) if $self->print_headers();
	return $self->_path_column_header_orders->{$path};

}

#when a href order is not know, generate it using the leadkeys as the first ones (e.g. always put the id column in position 0)
sub _get_column_order_for_href {

	my ( $self, $href ) = @_;
	my @keys = keys( %{$href} );
	my @junkeys;
	my $return = [];

	#I am not happy about how this is written, but it's abstracted enough to be less awful one day
	while ( my $key = shift( @keys ) ) {
		THISKEY: {
			for my $lead_key ( @{$self->lead_keys} ) {
				if ( $lead_key eq $key ) {
					push( @{$return}, $key );
					next THISKEY;
				}
			}
			push( @junkeys, $key );
		}
	}
	push( @{$return}, sort ( @junkeys ) );
	return $return;

}

sub _get_csv {

	use Text::CSV;
	Text::CSV->new( {binary => 1, eol => "\n"} ) or die "Cannot use CSV: " . Text::CSV->error_diag();

}
1;
