# ABSTRACT: Common use case of a working directory - very similar to tmpdir in Moo::GenericRole::FileSystem but for more permanent undertakings
package Moo::GenericRole::FileSystem::WorkingDirectory;

our $VERSION = 'v1.4.2';
##~ DIGEST : f21140fdc654ca105612bdc118d192d3

use Moo::Role;
with qw/Moo::GenericRole/;

ACCESSORS: {

	#Where all instances of $this_program store the working files - at the highest level
	has master_directory => (
		is => 'ro',

		#may not always be used
		lazy => 1,
	);

	has working_directory => (
		is      => 'rw',
		lazy    => 1,
		default => sub {
			my ( $self ) = @_;
			$self->make_path( $self->master_directory() );
			my $dir = $self->build_time_path( $self->master_directory() );
			$self->make_path( $dir );
			return $dir;
		},
	);
}

1;
