package Moo::GenericRole::FileIO;
our $VERSION = 'v2.0.2';
##~ DIGEST : 7488228815b08d0917d181900cb1e9d3
# ABSTRACT: persistent file IO
use Toolbox::FileIO;
use Moo::Role;
ACCESSORS: {
	has file_handles => (
		is      => 'rw',
		lazy    => 1,
		default => sub {
			return {};
		}
	);
}

# Almost but not quite cargo cultin'
sub ofh {

	my ( $self, $path, $c ) = @_;
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

sub closefhs {

	my ( $self, $paths ) = @_;

	#close all unless specific
	$paths ||= [ keys( %{$self->file_handles} ) ];
	use Data::Dumper;
	for ( @{$paths} ) {
		close( $self->file_handles->{$_} )
		  or confess( "Failed to close file handle for [$_] : $!" );
		undef( $self->file_handles->{$_} );
	}

}
1;
