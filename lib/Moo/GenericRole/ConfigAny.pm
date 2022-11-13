# ABSTRACT : use Config::Any and Config::Any::Merge the way I like in Moo::Role form
package Moo::GenericRole::ConfigAny;
our $VERSION = 'v1.0.1';
##~ DIGEST : f86d5f49dd21ec37bee3a9f87c7d218b

use strict;
use Moo;
use 5.006;
use warnings;
use Config::Any;
use Config::Any::Merge;

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

	has something => (
		is      => 'rw',
		lazy    => 1,
		default => sub { return 0 }
	);
}

=head1 SUBROUTINES/METHODS
=head2 LIFECYCLE SUBS
=cut

=head2 PRIMARY SUBS
	Main purpose of the module
=head3
=cut

sub config_dir {
	my ( $self, $path ) = @_;
	my $return = {};
	if ( $path ) {
		$self->check_dir( $path );
		my @cfiles;
		$self->sub_on_directory_files(
			sub {
				my ( $file ) = @_;
				push( @cfiles, $file );
			},
			$path
		);

		$return = Config::Any::Merge->load_files(
			{
				files   => \@cfiles,
				use_ext => 1
			}
		) or die "failed to load configuration file : $!";
	}
	return $return; # return!
}

sub config_file {

	my ( $self, $path ) = @_;
	my $return = {};
	if ( $path ) {
		$self->check_file( $path );

		$return = Config::Any::Merge->load_files(
			{
				files   => [$path],
				use_ext => 1
			}
		) or die "failed to load configuration file : $!";
	}
	return $return; # return!
}

sub config_file_dir {

	my ( $self, $c ) = @_;

	# if this fires, nothing is produced but no errors either
	$c ||= {};
	my $return      = {};
	my $dir_config  = $self->config_dir( $c->{config_dir} );
	my $file_config = $self->config_file( $c->{config_file} || $c->{cfg} );
	$return = Hash::Merge::merge( $dir_config, $file_config );

	return $return; # return!
}

=head1 AUTHOR
	mmacnair, C<< <mmacnair at cpan.org> >>
=head1 BUGS
	TODO Bugs
=head1 SUPPORT
	TODO Support
=head1 ACKNOWLEDGEMENTS
	TODO
=head1 COPYRIGHT
 	Copyright 2022 mmacnair.
=head1 LICENSE
	TODO
=cut

1;
