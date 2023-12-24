# ABSTRACT : Time::Out as a Moo role with conventions
package Moo::GenericRole::TimeOut;
use strict;
use warnings;

our $VERSION = 'v1.0.12';
##~ DIGEST : d2f33fac6240fd2d7cd96896ac483a95

use Moo::Role;
use 5.006;
use Carp;
use Time::Out;

ACCESSORS: {
	has default_timeout => (
		is       => 'rw',
		required => 0,
		default  => sub {
			return 1;
		}
	);
}

sub timeout_sub {
	my ( $self, $sub, $p ) = @_;
	$p ||= {};
	my $seconds = $p->{seconds} || $self->{default_timeout};
	my $return;
	Time::Out::timeout(
		$seconds,
		sub {
			$return = &$sub;
		}
	);
	if ( $@ ) {
		$return = {fail => 'Timeout',};
	}
	return $return; #return!
}
