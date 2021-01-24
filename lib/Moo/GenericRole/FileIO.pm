#ABSTRACT: do file read/write with accessors
package Moo::GenericRole::FileIO;
our $VERSION = 'v2.0.14';
##~ DIGEST : f4bf50ee401db57b7bad8a21751abd7b
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
	if ( wantarray() ) {
		return ( $self->file_handles->{$path}, $path );
	} else {
		return $self->file_handles->{$path};
	}
}

=head3 ifh
	given a path, return a read file handle which may/not have been opened already
=cut

sub ifh {
	my ( $self, $path, $c ) = @_;
	$path =~ s|/[/]+|/|g;
	$c ||= {};
	unless ( exists( $self->file_handles->{$path} ) ) {
		if ( $c->{fh} ) {
			$self->file_handles->{$path} = $c->{fh};
		} else {
			unless ( open( $self->file_handles->{$path}, $c->{openparams} || "<:raw", $path ) ) {
				confess( "Failed to open write file [$path] : $!" );
			}
		}
	}
	if ( wantarray() ) {
		return ( $self->file_handles->{$path}, $path );
	} else {
		return $self->file_handles->{$path};
	}

}

sub sub_on_input_file {

	my ( $self, $sub, $path ) = @_;
	die "[$path] not found" unless ( -e $path );
	die "sub isn't a code reference" unless ( ref( $sub ) eq 'CODE' );
	my $ifh;
	( $ifh, $path ) = $self->ifh( $path );

	while ( < $ifh > ) {
		last unless &$sub( $_ );
	}
	$self->close_fhs( [$path] );

}

#flush ofh immediately
sub hot_ofh {

	my ( $self, $path ) = @_;
	my $ofh = $self->ofh( $path );

	#cargo culting like a boss
	select( $ofh );
	$| = 1;
	return $ofh;

}

sub closefhs {

	my ( $self, $paths ) = @_;
	warn "Obsolete method name!";
	$self->close_fhs( $paths );

}

=head3 sub_on_file_lines 
	open a file with guard rails and do $something on each line 
=cut

sub sub_on_file_lines {
	my ( $self, $sub, $path ) = @_;
	open( my $fh, '<:raw', $path ) or die $!;
	while ( <$fh> ) {
		last unless &$sub( $_ );
	}
	close( $fh ) or die $!;
	return 1;

}

sub close_fhs {
	my ( $self, $paths ) = @_;

	# TODO single if single
	#close all unless specific
	$paths ||= [ keys( %{$self->file_handles} ) ];

	#no error if there's none open
	return unless @{$paths};
	for my $path ( @{$paths} ) {
		$path =~ s|/[/]+|/|g;
		if ( $self->file_handles->{$path} ) {
			close( $self->file_handles->{$path} ) or confess( "Failed to close file handle for [$path] : $!" );
		}
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
