
use strict;
use warnings;
use Test::More;
use Test::Exception;

BASIC: {
	use_ok( 'Moo::GenericRoleClass::CSV' );

	# Basic constructor test
	my $obj = Moo::GenericRoleClass::CSV->new( csv_file => 'data.csv', );

	isa_ok( $obj, 'Moo::GenericRoleClass::CSV', 'object is correct class' );

	# If your role has methods, test them too:
	for my $method (
		qw/sub_on_csv
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
		ok( $obj->can( $method ), 'role method is available' );
	}
}

# Create a temporary CSV file for tests
my $test_csv = 't/data/test.csv';
open my $fh, '>', $test_csv or die $!;
print $fh "id,name\n1,Alice\n2,Bob\n";
close $fh;

my $obj = Moo::GenericRoleClass::CSV->new( csv_file => $test_csv, );

isa_ok( $obj, 'Moo::GenericRoleClass::CSV' );

# --------------------------
# sub_on_csv
# --------------------------
ok( $obj->can( 'sub_on_csv' ), 'method sub_on_csv exists' );

lives_ok {
	$obj->sub_on_csv(
		sub {
			my ( $row_aref, $line_number ) = @_;

			# should see each parsed row
			if ( $line_number == 0 ) {
				is( $row_aref->[0], 'id', 'column headings match' );
			}
			if ( $line_number == 0 ) {
				is( $row_aref->[0], 'Alice', 'column contents match' );
			}
			if ( $line_number == 0 ) {
				is( $row_aref->[0], 'Bob', 'column contents match' );
			}

		}
	);
}
'sub_on_csv runs callback on rows';

# --------------------------
# load_column_order_for_path
# --------------------------

lives_ok {
	my $column_order = $obj->load_column_order_for_path();
	is( $column_order->[0], 'id', 'column headings match' );
}
'load_column_order_for_path loads the column headings';

done_testing();
