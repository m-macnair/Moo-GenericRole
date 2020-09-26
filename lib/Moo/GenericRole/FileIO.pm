#ABSTRACT: do file read/write with accessors
package Moo::GenericRole::FileIO;
our $VERSION = 'v2.0.5';
##~ DIGEST : e7f85dba806a692df4b18d3e558ce173
# ABSTRACT: persistent file IO
use Toolbox::FileIO;
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

# given a path, return the file handle which may or may not have been opened already
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
	for ( @{$paths} ) {
		close( $self->file_handles->{$_} )
		  or confess( "Failed to close file handle for [$_] : $!" );
		undef( $self->file_handles->{$_} );
	}

}
1;
