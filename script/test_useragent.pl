#!/usr/bin/perl
use strict;
use warnings;
use Toolbox::CombinedCLI;

package TestObj;
use Moo;
with qw/
  Moo::GenericRole::UserAgent
  /;
1;

package main;
main();

sub main {

	my $obj = TestObj->new();

}
