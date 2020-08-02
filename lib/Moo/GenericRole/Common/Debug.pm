use strict;

package Moo::GenericRole::Common::Debug;
our $VERSION = 'v1.0.1';
##~ DIGEST : e082540804274d445aaa1fe7984d76ad

use Moo::Role;
use 5.006;
use warnings;

=head1 NAME
	Common Debug - wrapper around future debug methods for when I eventually find one I like
=head1 VERSION & HISTORY
	
	0.01 - 2020-07-26
		mk1
=cut

=head1 SYNOPSIS
	TODO
=head2 TODO
	Generall planned work
=head1 ACCESSORS
=cut

ACCESSORS: {

	#debug level
	has debug => (
		is      => 'rw',
		lazy    => 1,
		default => sub { return 0 }
	);
}

=head1 SUBROUTINES/METHODS
=head2 PRIMARY SUBS
	Main purpose of the module
=head3 debug_msg
	given a message and optional message level, determine if the system's debug state matches the message level and record the message accordingly 
=cut

sub debug_msg {

	my ( $self, $msg, $msg_lvl ) = @_;
	$msg_lvl ||= 1;

	if ( $msg_lvl >= $self->debug() ) {
		my $debug_method = "debug_msg_$msg_lvl";
		if ( $self->can( $debug_method ) ) {
			$self->$debug_method( $msg );
			return 1;
		} else {
			confess( "Unsupported message level $msg_lvl" );
		}
	}

	return;

}

=head2 SPECIFIC DEBUG ACTIONS
	typically overwritten (probably with an OFH) 
=cut

sub debug_msg_1 {
	my ( $self, $msg ) = @_;
	Carp::cluck( $msg );
}

sub debug_msg_2 {
	my ( $self, $msg ) = @_;
	$self->debug_msg_1( $msg );

}

sub debug_msg_3 {
	my ( $self, $msg ) = @_;
	$self->debug_msg_1( $msg );

}

sub debug_msg_4 {
	my ( $self, $msg ) = @_;
	$self->debug_msg_1( $self->morale_msg );
	$self->debug_msg_1( $msg );

}

=head3 morale_msg
	This is more helpful than I care to admit
=cut

sub morale_msg {
	my @msgs    = ( 'You can do it!', 'You can find the bug!', 'The code believes in you!', 'Take a 5 minute break', "Try writing out the problem by hand, make sure you're solving what you're trying to solve", 'Consult the rubber duck cabal, or a nearby friend', 'Try some bikeshedding of method names for a while, might help highlight what is actually happening', 'Permissions problem maybe?', 'Have a look at the network stack', 'Needs moar Carp::cluck(Dumper());', 'Go get a breath of fresh air - can only help', 'Coffee/Sugar/Solvent paucity detected', 'Insufficient :metal:; adjust with Dancing With Myself by Billy Idol', 'Seek additional morale improvement methods','Check the actual file paths are what you think they are' );
	my $pointer = int( rand( scalar( @msgs ) ) - 1 );
	return $msgs[$pointer];

}

=head2 SECONDARY SUBS
	Actions used by one or more PRIMARY SUBS that aren't wrappers
=cut

=head2 WRAPPERS
=head3 external_function
=cut

=head1 AUTHOR
	mmacnair, C<< <mmacnair at cpan.org> >>
=head1 BUGS
	TODO Bugs
=head1 SUPPORT
	TODO Support
=head1 ACKNOWLEDGEMENTS
	TODO
=head1 COPYRIGHT
 	Copyright 2020 mmacnair.
=head1 LICENSE
	TODO
=cut

1;
