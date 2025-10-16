#ABSTRACT: Do the thing I do for command line scripts
package Moo::GenericRoleClass::CSV;
our $VERSION = 'v0.0.3';
##~ DIGEST : a79a47b07e1f2ba9bb62685a147056fa

use Moo;
use Carp;
with qw/
  Moo::GenericRole::FileIO
  Moo::GenericRole::FileIO::CSV
  /;
ACCESSORS: {
	has csv_file => (
		is       => 'rw',
		required => 1
	);
}

#file is second variable
for my $method (
	qw/
	sub_on_csv
	sub_on_csv_href
	aref_to_csv
	href_to_csv
	href_sub_to_csv
	sth_href_to_csv
	sth_aref_to_csv
	set_column_order_for_path

	/
  )
{
	around $method => sub {
		my ( $orig, $self, @args ) = @_;
		$args[1] //= $self->csv_file();
		return $self->$orig( @args );
	};
}

#file is first (only) variable
for my $method (
	qw/
	load_column_order_for_path

	/
  )
{
	around $method => sub {
		my ( $orig, $self, @args ) = @_;
		$args[0] //= $self->csv_file();
		return $self->$orig( @args );
	};
}

1;
