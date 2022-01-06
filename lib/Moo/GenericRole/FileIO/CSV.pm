#ABSTRACT : Do common things with CSV files
package Moo::GenericRole::FileIO::CSV;
use strict;
use warnings;
our $VERSION = 'v2.1.5';
##~ DIGEST : ef8a67b3bcbd23e36375409541c9ba3d
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

	#explicit "put these keys first" arref for all cases
	has lead_keys => (
		is      => 'rw',
		lazy    => 1,
		default => sub {
			[];
		}
	);

	#lead_keys but for individual files - 'should' instead of _path_column_header_orders 'is'
	has file_lead_keys => (
		is      => 'rw',
		lazy    => 1,
		default => sub {
			{};
		}
	);
}

# do something on csv rows that aren't commented out until something returns falsey
sub sub_on_csv {

	my ( $self, $sub, $path ) = @_;
	die "[$path] not found"          unless ( -e $path );
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

=head3 sub_on_csv_href
	As above, but provide each row as a href assuming the first line in the file is the key headings
=cut 

sub sub_on_csv_href {

	my ( $self, $sub, $path ) = @_;
	my $heading_map = {};
	my $first_row   = 1;
	$self->sub_on_csv(
		sub {
			my ( $row ) = @_;
			my $cell_counter = 0;
			if ( $first_row ) {

				#there's a better way to do this, but for now ~ s
				for my $cell ( @{$row} ) {
					$heading_map->{$cell_counter} = $cell;
					$cell_counter++;
				}
				$first_row = 0;
				return 1;
			} else {

				#originally this was the other way around leading to variable size hrefs which is exactly not what was wanted
				my $href = {};
				for my $row_position ( keys( %{$heading_map} ) ) {
					$href->{$heading_map->{$row_position}} = $row->[$row_position];
				}
				return &$sub( $href );
			}
		},
		$path
	);

}

#given a csv path and a column number, return all rows for that column
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
	my $ofh = $self->ofh( $path );
	$self->csv->print( $ofh, $row );

}

#given a href and a path, do the right thing
sub href_to_csv {

	my ( $self, $href, $path ) = @_;

	my $column_order = $self->_path_column_header_orders->{$path} || $self->_init_path_columns( $href, $path );
	my $ofh          = $self->ofh( $path );
	$self->csv->print( $ofh, [ @{$href}{@{$column_order}} ] );

}

=head3 href_sub_to_csv
		To handle a specific and not uncommon problem - what do you do when the keys for 1-n hrefs are not the same?
		Answer: write a temp file with column orders as they come, then write the column headings afterwards 
		While sub returns hrefs, print columns in expected order to file, then push the column headings that have been discovered into row 0
		Significantly, this ignores lead_keys
=cut

sub href_sub_to_csv {

	my ( $self, $sub, $path, $p ) = @_;
	$p ||= {};
	my $temp_path       = $path . '.tmp';
	my $column_headings = [];
	my $column_map      = {};
	my $temp_ofh        = $self->ofh( $temp_path );
	while ( my $hrefs = &$sub( $column_headings, $column_map ) ) {
		if ( ref( $hrefs ) eq 'HASH' ) {
			$hrefs = [$hrefs];
		}
		for my $href ( @{$hrefs} ) {

			#First line
			unless ( @{$column_headings} ) {
				$column_headings = $self->_path_column_header_orders->{$path} || $self->_init_path_columns( $href, $path, {skip_print_headers => 1} );
				for ( 0 .. $#$column_headings ) {
					my $column_heading = $self->_process_href_sub_to_csv_key( $column_headings->[$_] );
					$column_map->{$column_heading} = $_;
				}
			}

			#check for unknown keys
			for my $key ( keys( %{$href} ) ) {
				my $test_key = $self->_process_href_sub_to_csv_key( $key );
				unless ( exists( $column_map->{$test_key} ) ) {
					push( @{$column_headings}, $test_key );
					$column_map->{$test_key} = $#$column_headings;
				}
			}

			#print to temp file with current known keys
			$self->csv->print( $temp_ofh, [ @{$href}{@{$column_headings}} ] );
		}
	}
	$self->close_fhs( [$temp_path] );

	#start again, with the exact known headings as line 0
	my $ofh = $self->ofh( $path );
	$self->csv->print( $ofh, $column_headings );

	#re-read the file just written into the actual output file
	my $ifh = $self->ifh( $temp_path );
	while ( <$ifh> ) {
		print $ofh $_;
	}
	$self->close_fhs( [ $temp_path, $path ] );
	unlink( $temp_path );
}

sub _process_href_sub_to_csv_key {
	my ( $self, $key, $p ) = @_;
	if ( $p->{case_insensitive} ) {
		$key = lc( $key );
	}

	#etc. etc.
	return $key;

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

	my ( $self, $v, $path, $p ) = @_;
	$p ||= {};
	if ( ref( $v ) eq 'HASH' ) {
		my ( $want, $surplus );
		my @keys = keys( %{$v} );
		if ( $self->file_lead_keys()->{$path} ) {
			( $want, $surplus ) = $self->_split_key_sets( \@keys, $self->file_lead_keys()->{$path} );
		} else {

			( $want, $surplus ) = $self->_split_key_sets( \@keys, $self->lead_keys() );

		}
		$self->_path_column_header_orders->{$path} = [ @{$want}, @{$surplus} ];
	} elsif ( ref( $v ) eq 'ARRAY' ) {
		$self->_path_column_header_orders->{$path} = $v;
	}
	unless ( $p->{skip_print_headers} ) {
		$self->aref_to_csv( $self->_path_column_header_orders->{$path}, $path ) if $self->print_headers();
	}
	return $self->_path_column_header_orders->{$path};

}

=head3 _split_key_sets
"Given want_keys and have_keys, return arref in submitted order of wanted keys found, and sorted arref of the rest"
=cut 

sub _split_key_sets {
	my ( $self, $have_keys, $want_keys ) = @_;

	my $map = {};
	for ( @{$have_keys} ) {
		$map->{$_} = 1;
	}

	my ( $wanted, $surplus ) = ( [], [] );

	for my $wanted_key ( $want_keys ) {
		if ( exists( $map->{$wanted_key} ) ) {
			push( @{$wanted}, $wanted_key );
			delete( $map->{$wanted_key} );
		}
	}
	$surplus = [ sort( keys( %{$map} ) ) ];
	return ( $wanted, $surplus );
}

#Overkill but consistent
sub set_column_order_for_path {
	my ( $self, $column_order, $path ) = @_;
	$self->file_lead_keys()->{$path} = $column_order;
	return;
}

=head3 reorder_csv
	Given a CSV, reprocess with lead_keys and file_lead_keys as the column order, and any other columns in sorted order
=cut

sub reorder_csv {
	my ( $self, $in_path, $out_path ) = @_;
	die "input file [$in_path] not found" unless -e $in_path;
	$out_path = $self->get_safe_path( $out_path );
	$self->sub_on_csv_href(
		sub {
			my ( $row ) = @_;
			$self->href_to_csv( $row, $out_path );
		},
		$in_path
	);

}

sub _get_csv {

	use Text::CSV;
	Text::CSV->new( {binary => 1, eol => "\n"} ) or die "Cannot use CSV: " . Text::CSV->error_diag();

}
1;
