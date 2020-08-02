#!/usr/bin/perl
use strict;
use warnings;

package TestObj;
use Moo;
with qw/
	Moo::GenericRole::AWS::Paws
/;

1;

package main;
main();

sub main {

	my $obj      = TestObj->new();
	print $obj->ddumper($obj->any_paws);

}
