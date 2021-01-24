use strict;

# ABSTRACT : Present interactive command line menus that dispatch to other object methods
package Moo::GenericRole::InteractiveCLI;

our $VERSION = 'v1.0.2';
##~ DIGEST : 75a5f444d2d86f61105546e6047634ed

use Moo::Role;
use 5.006;
use warnings;
use Carp qw/confess/;
use Term::UI;
use Term::ReadLine;

=head1 NAME
	~
=head1 VERSION & HISTORY
	<breaking revision>.<feature>.<patch>
	1.0.0 - <date>
		<actions>
	1.0.0 - <date unless same as above>
		The Mk1
=cut

=head1 SYNOPSIS
	TODO
=head2 TODO
	Generall planned work
=head1 ACCESSORS
=cut

ACCESSORS: {

	has term_readline => (
		is      => 'rw',
		lazy    => 1,
		default => sub {
			my ( $self ) = @_;
			$self->_build_term_readline( 'Default' );
		}
	);
}

=head1 SUBROUTINES/METHODS
=head2 PRIMARY SUBS
	I am 90% sure that a lot of this was provided batteries included back in 2015, but for love nor money I cannot find what I used to do it
=head3 numerical_term_readline_menu
	given a href with prompt and arref of response -> method pairs and some non-defaults, generate a numerical menu with defaults and dispatch to the corresponding method
=cut

sub numerical_term_readline_menu {
	my ( $self, $p, $method_p ) = @_;
	if ( scalar( @{$p->{choices}} ) > 9 ) {
		confess( "Numerical term menu will not process more than 9 options correctly" );
	}

	#setup
	my ( $mapping, $order ) = $self->_shared_menu_prep( $p, $method_p );

	my $menu_counter;
	my $revised_order;
	my $default_option_number;
	for my $option_string ( @{$order} ) {
		$menu_counter++;
		$mapping->{$menu_counter} = $mapping->{$option_string};
		push( @{$revised_order}, "$menu_counter : $option_string" );
		if ( $p->{'default'} ) {
			if ( $option_string eq $p->{'default'} ) {
				$default_option_number = $menu_counter;
			} else {
				warn "$mapping->{$option_string} eq $p->{'default'} ? ";
			}
		}
	}
	unless ( $p->{no_quit_option} ) {
		my $quit_string = $p->{quit_string} || 'Quit';
		push( @{$revised_order}, "0 : $quit_string" );
	}
	my $prompt_string = "$p->{prompt}:$/" . join( $/, @{$revised_order} ) . $/;

	$prompt_string .= $p->{post_prompt} || '';
	if ( $p->{'default'} ) {
		$prompt_string .= "(Default $default_option_number)$/";
	}

	#display menu - this supports nested menus
	while ( 1 ) {

		$self->set_named_term_readline( $p->{terminal_name} ) if $p->{terminal_name};
		print $prompt_string;
		my $reply = $self->term_readline->readline( '' );

		if ( $mapping->{$reply} ) {
			my $method_name = $mapping->{$reply};
			last unless $self->$method_name( $p, $method_p );
		} elsif ( $reply eq '0' && !$p->{no_quit_option} ) {
			last;
		} elsif ( $p->{'default'} ) {
			my $method_name = $mapping->{$default_option_number};
			last unless $self->$method_name( $p, $method_p );
		}
	}

}

=head3 term_readline_menu
	given a href with prompt and arref of response -> method pairs and some non-defaults, present a prompt, take the user's choice, and pass the href and optional method variable reference to the selected method, repeating until the method returns undef
=cut

sub simple_term_readline_menu {
	my ( $self, $p, $method_p ) = @_;

	#setup
	my ( $mapping, $order ) = $self->_shared_menu_prep( $p, $method_p );

	#display menu - this supports nested menus
	while ( 1 ) {

		$self->set_named_term_readline( $p->{terminal_name} ) if $p->{terminal_name};
		my $get_reply_params = {
			prompt  => $p->{prompt},
			choices => $order
		};

		my $reply = $self->term_readline->readline( "$p->{prompt}$/" );
		if ( $reply ) {
			if ( $mapping->{$reply} ) {
				my $method_name = $mapping->{$reply};
				last unless $self->$method_name( $p, $method_p );
			} else {
				print "Invalid response$/";
			}

		}
	}
}

=head2 SECONDARY SUBS
=head3 _shared_menu_prep
=cut

sub _shared_menu_prep {
	my ( $self, $p, $method_p ) = @_;
	$self->demand_params(
		$p,
		[
			qw/
			  prompt
			  choices

			  /
		]
	);

	my ( $mapping, $order ) = ( {}, [] );
	use Data::Dumper;

	for my $pair ( @{$p->{choices}} ) {
		my ( $key ) = keys( %{$pair} );

		unless ( $self->can( $pair->{$key} ) ) {
			confess( "Method to simple_term_readline_menu [$pair->{$key}] is not implemented by this object" );
		}

		$mapping->{$key} = $pair->{$key};
		push( @{$order}, $key );
	}
	return ( $mapping, $order );
}

=head3 set_named_term_readline
	create and set accessor for named terminal
=cut

sub set_named_term_readline {
	my ( $self, $name ) = @_;
	my $t = $self->_build_term_readline( $name );
	$self->term_readline( $t );
	return $t;
}

=head3 _build_term_readline
	Term::ReadLine->new();
=cut

sub _build_term_readline {
	my ( $self, $name ) = @_;
	return Term::ReadLine->new( $name );
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
