package Moo::GenericRole::JSON;
use Moo::Role;
our $VERSION = 'v1.0.8';
##~ DIGEST : 4b666f8c14773e658db92cb0f3a33bfe
# enable $self->json and sugar
use JSON;
use Try::Tiny;
ACCESSORS: {
	has json => (
		is      => 'rw',
		lazy    => 1,
		default => sub {
			JSON->new();
		}
	);
}

#copied wholesale from Toolbox::JSON
sub jsonloadfile {

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

#copied wholesale from Toolbox::JSON x2
sub jsonloadall {

	my ( $self, $path ) = @_;
	confess( "non-existent path [$path]" ) unless ( -e $path );
	my $return;
	if ( -f $path ) {
		$return->{$path} = $self->jsonloadfile( $path );
	} elsif ( -d $path ) {
		require File::Find::Rule;
		my @files = File::Find::Rule->file()->name( '*.json' )->in( $path );
		for my $file ( @files ) {
			$return->{$file} = $self->jsonloadfile( $file );
		}
	}
	return $return; # return!

}
1;
