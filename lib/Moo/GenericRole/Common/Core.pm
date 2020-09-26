
#ABSTRACT: things I rely on, but aren't universally necessary
package Moo::GenericRole::Common::Core;
use strict;
our $VERSION = 'v1.0.9';
##~ DIGEST : 71bc4a44c32c09a0c470e347850d2eb9
use Moo::Role;
use 5.006;
use Data::Dumper;
use warnings;
use Carp qw/confess/;

=head1 NAME
	Common Core - my way of doing things
=head1 VERSION & HISTORY
	<feature>.<patch>
	1.0.0 - 2020-07-26
		The Mk1
=cut

=head1 SYNOPSIS
	The things I always do and/or need
=head2 TODO
	Generall planned work
=head1 ACCESSORS
=cut

=head1 SUBROUTINES/METHODS
=head2 PRIMARY SUBS
	Main purpose of the module
=head3 demand_params
	halt and catch fire if a hashref isn't built as expected
=cut

sub demand_params {

	my ( $self, $map, $list ) = @_;
	confess( "\$map is not a map, is instead : " . Dumper( $map ) )
	  unless ref( $map ) eq 'HASH';
	confess( "\$list is not a list, is instead : " . Dumper( $list ) )
	  unless ref( $list ) eq 'ARRAY';
	my $msg;
	CHECK: {
		for my $check ( @{$list} ) {
			THISCHECK: {
				my $ref = ref( $check );

				#"If one of these values is present, move on"
				if ( $ref eq 'ARRAY' ) {
					for my $subcheck ( @{$check} ) {
						if ( defined( $map->{$subcheck} ) ) {
							next THISCHECK;
						}
					}
					$msg = "None of [" . join( ',', @{$check} ) . "] provided in \$map";
					last CHECK;
				} elsif ( $ref ) {
					$msg = "Non SCALAR, Non ARRAY reference [$ref] passed in \$list";
					last CHECK;
				} else {
					unless ( $map->{$check} ) {
						$msg = "Required key [$check] missing in \$map";
						last CHECK;
					}
				}
			}
		}
	}
	if ( $msg ) {
		confess( "$msg - \$map :\n\t" . Dumper( $map ) );
	}
	return;

}

#use Data::Dumper in a way that can be changed to Carp::cluck(Data::Dumper::Dumper()); when it's not clear where the actual dump is coming from
sub ddumper {

	my ( $self, $v ) = @_;
	require Data::Dumper;
	return Data::Dumper::Dumper( $v );

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
