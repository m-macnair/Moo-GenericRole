#ABSTRACT: enable $self->json and sugar
package Moo::GenericRole::JSON;
our $VERSION = 'v1.0.13';
##~ DIGEST : 27bc0537638ecaa85f2cfc5c14e57a20
use Moo::Role;
with qw/Moo::GenericRole/;
use JSON;
use Try::Tiny;
ACCESSORS: {
	has json => (
		is      => 'rw',
		lazy    => 1,
		default => sub {
			my ( $self ) = @_;
			$self->_get_json();
		}
	);
}

#to be replaced when it makes sense - e.g. to init a special case JSON object
sub _get_json {

	JSON->new();
}

=head3 json_load_file
	Read a json file and return as href
=cut

sub json_load_file {

	my ( $self, $path ) = @_;
	my $buffer = '';
	my $struct;
	try {
		open( my $fh, '<:raw', $path )
		  or die "failed to open file [$path] : $!";

		# :|
		while ( my $line = <$fh> ) {
			chomp( $line );
			$buffer .= $line;
		}
		close( $fh );
		$struct = $self->json->decode( $buffer );
	} catch {
		confess( "Failed - $_" );
	};
	return $struct;

}

sub json_write_href {
	my ( $self, $path, $href ) = @_;
	my $json_string = $self->json->encode( $href );
	my $ofh         = $self->ofh( $path );
	print $ofh $json_string;
	$self->closefhs( [$path] );

}

=head3 json_load_directory
	load an entire directory of json files
=cut

sub json_load_directory {

	my ( $self, $path ) = @_;
	confess( "non-existent path [$path]" ) unless ( -e $path );
	my $return;
	if ( -f $path ) {
		$return->{$path} = $self->json_load_file( $path );
	} elsif ( -d $path ) {
		require File::Find::Rule;
		my @files = File::Find::Rule->file()->name( '*.json' )->in( $path );
		for my $file ( @files ) {
			$return->{$file} = $self->json_load_file( $file );
		}
	}
	return $return; # return!

}

sub jsonloadfile {
	cluck( "Obsolete method name" );
	my $self = shift;
	$self->json_load_file( @_ );
}

sub jsonloadall {

	cluck( "Obsolete method name" );
	my $self = shift;
	$self->json_load_directory( @_ );
}
1;
