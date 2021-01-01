#ABSTRACT: do file read/write with accessors
package Moo::GenericRole::FileIO;
our $VERSION = 'v2.0.8';
##~ DIGEST : 454a32cbf2adbc9d68333448fdb7199a
# ABSTRACT: persistent file IO
use Moo::Role;
with qw/Moo::GenericRole/;
ACCESSORS: {
	has file_handles => (
		is      => 'rw',
		lazy    => 1,
		default => sub {
			return {};
		}
	);
}

# given a path, return a write file handle which may or may not have been opened already
sub ofh {

	my ( $self, $path, $c ) = @_;

	#because this almost hit me - remove duplicate forward slashes which would map to the same file in the file system, but not this module
	$path =~ s|/[/]+|/|g;
	$c ||= {};
	unless ( exists( $self->file_handles->{$path} ) ) {
		if ( $c->{fh} ) {
			$self->file_handles->{$path} = $c->{fh};
		} else {
			unless ( open( $self->file_handles->{$path}, $c->{openparams} || ">:encoding(UTF-8)", $path ) ) {
				confess( "Failed to open write file [$path] : $!" );
			}
		}
	}

	return $self->file_handles->{$path};

}

#flush ofh immediately
sub hot_ofh {

	my ( $self, $path ) = @_;
	my $ofh = $self->ofh( $path );

	#cargo culting like a boss
	select( $ofh );
	$|++;

}

sub closefhs {

	my ( $self, $paths ) = @_;

	#close all unless specific
	$paths ||= [ keys( %{$self->file_handles} ) ];
	use Data::Dumper;
	for my $path ( @{$paths} ) {
		$path =~ s|/[/]+|/|g;
		close( $self->file_handles->{$path} )
		  or confess( "Failed to close file handle for [$path] : $!" );
		undef( $self->file_handles->{$path} );
	}

}

=head3 slurp_file
	Load and use File::Slurp for the only thing I ever do with it
=cut

sub slurp_file {
	my ( $self, $path ) = @_;
	$self->check_file( $path );
	require File::Slurp;
	return File::Slurp::slurp( $path );
}
1;
