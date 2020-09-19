#!/usr/bin/perl
use strict;
use warnings;
use Toolbox::CombinedCLI;

package TestObj;
use Moo;
with qw/
  Moo::GenericRole::FileIO::CSV
  Moo::GenericRole::FileIO
  /;

1;

package main;
main();

sub main {

	my $self = TestObj->new();
	$self->lead_keys( [qw/ id /] );
	my $test_file = "./test.csv";
	for ( 1 ... 10 ) {
		$self->href_to_csv(
			{
				id     => $_,
				source => int( rand( 100 ) ),
				junk   => int( rand( 100 ) ),
				funk   => int( rand( 100 ) ),
				test   => int( rand( 100 ) ),
			},
			$test_file
		);
	}

}
