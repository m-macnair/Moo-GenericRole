use strict;

package Moo::GenericRole::AWS::Paws;
our $VERSION = '0.02';
##~ DIGEST : 78ad38bfe30fc92c38ebee155b2e0825

use Moo::Role;
use 5.006;
use warnings;

=head1 NAME
	~
=head1 VERSION & HISTORY
	<feature>.<patch>
	0.01 - <date>
		<actions>
	0.00 - <date unless same as above>
		<actions>
=cut

=head1 SYNOPSIS
	TODO
=head2 TODO
	Generall planned work
=head1 ACCESSORS
=cut

ACCESSORS: {

	has paws => (
		is   => 'rw',
		lazy => 1,
	);
}

=head1 SUBROUTINES/METHODS
=head2 PRIMARY SUBS
	Main purpose of the module
=head3
=cut

sub do_something {
	my ( $self, $p ) = @_;
	$p ||= {};
}

=head2 SECONDARY SUBS
	Actions used by one or more PRIMARY SUBS that aren't wrappers
=cut

sub paws_with_role_arn {
	my ( $self, $p, $value ) = @_;
	demand_params

}

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
