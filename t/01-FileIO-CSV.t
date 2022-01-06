package OBJ;
use Moo;
with qw/
  Moo::GenericRole::FileIO
  Moo::GenericRole::FileIO::CSV
  Moo::GenericRole::FileSystem
  /;

1;

use 5.006;
use strict;
use warnings;
use Test::More;

use Test::Exception;

my $module = $1       || 'Moo::GenericRole::FileIO::CSV';
use_ok( $module )     || BAIL_OUT "Failed to use $module : [$!]";
my $self = OBJ->new() || BAIL_OUT "Failed to construct role user module : [$!]";

my $data = [ {funky => 'fresh'}, {beats => 'ah'}, ];

$self->init_tmp_dir( './test/csv/' );
my $test_path_1 = $self->tmp_dir() . 'test_1.csv';
$self->href_sub_to_csv(
	sub {
		return shift( @{$data} );
	},
	$test_path_1
);

my $test_path_2 = $self->tmp_dir() . 'test_2.csv';

$self->reorder_csv( $test_path_1, $test_path_2 );

done_testing();
