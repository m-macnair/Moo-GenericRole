#ABSTRACT : use CGI sensibly
package Moo::GenericRole::TimeHiRes;
our $VERSION = 'v1.1.3';
##~ DIGEST : f5611375c6e9e172d0a8ec5591edeb27
use Moo::Role;
with qw/Moo::GenericRole/;
use Carp;
use Time::HiRes qw(usleep ualarm gettimeofday tv_interval);

=head3 sub_in_time_loop

	given a sub and seconds , pass in (<faster than target>, duration_seconds, duration_microseconds) until the sub says to stop
	written specifically to drift towards a consistent processing time with a variable chunk size in a work load - lock table, dump as many rows as possible in under x seconds and unlock table
	
=cut

sub timed_loop_sub {

	my ( $self, $sub, $target ) = @_;
	Carp::confess( "Not a valid sub" ) unless ref( $sub ) eq 'CODE';
	my $continue = 1;
	my ( $faster, $seconds, $ms ) = ( 1, 0, 0 );
	while ( $continue ) {

		my $start = [gettimeofday];
		$continue = &$sub( $faster, $seconds, $ms );
		( $seconds, $ms ) = split( '\.', tv_interval( $start ) );
		$ms ||= 0;
		$faster = $target > $seconds;
	}
	return;
}

1;
