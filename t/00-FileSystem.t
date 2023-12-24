package OBJ;
use Moo;
with qw/Moo::GenericRole::FileSystem/;

1;

use 5.006;
use strict;
use warnings;
use Test::More;

use Test::Exception;

my $module = $1   || 'Moo::GenericRole::FileSystem';
use_ok( $module ) || BAIL_OUT "Failed to use $module : [$!]";
my $obj      = OBJ->new() || BAIL_OUT "Failed to construct role user module : [$!]";
my $tmp_root = './test/FileSystem';
$obj->init_tmp_dir( $tmp_root );

$obj->tmp_dir();
my ( $path, $exists ) = $obj->make_path( $obj->tmp_dir() );
$exists || BAIL_OUT "tmp_dir either didn't create a directory, or exists check returned null";
dies_ok( sub { $obj->get_safe_path( $obj->tmp_dir(), {fatal => 1} ) } );
my $dupe_path = $obj->get_safe_path( $obj->tmp_dir() );
diag "[Processing directory $dupe_path]";
$obj->make_path( $dupe_path );

for my $num ( 1 ... 10 ) {
	`echo date > $dupe_path/$num.txt`;
}
$obj->sub_on_find_files(
	sub {
		my ( $file ) = @_;
		diag( "got file [$file]" );
		$obj->safe_mvf( $file, $obj->tmp_dir() );

	},
	$dupe_path
);

for ( $obj->tmp_dir(), $dupe_path ) {
	`rm -rf $_`;
}

done_testing();
