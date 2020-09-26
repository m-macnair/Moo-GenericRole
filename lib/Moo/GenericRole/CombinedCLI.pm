# ABSTRACT : perform and preserve command line interaction
package Moo::GenericRole::CombinedCLI;
our $VERSION = 'v1.0.11';
##~ DIGEST : 494d79bfecc8be625d45e621145fdda8

require Getopt::Long;
require Config::Any::Merge;
require Hash::Merge;

use Moo::Role;
with qw/Moo::GenericRole/;

ACCESSORS: {
	has cfg => (
		is   => 'rw',
		lazy => 1,
	);
}

after new => sub {
	my ( $self ) = @_;
	$self->_verify_methods( [qw/sub_on_directory_files /] );
};

sub get_config {

	my $self = shift;
	my $cfg  = $self->get_combined_config( @_ );

	$self->cfg( $cfg );

}

=head3 get_combined_config
	given an arref of required, an arref of optional with some defaults and a href of optional switches, generate a configuration href which does what I expect it to do
=cut

sub get_combined_config {

	my ( $self, $required, $optional, $p ) = @_;

	$required ||= [];
	$optional ||= [];
	$p        ||= {};
	my $default_values = $p->{'default'} || {};

	push( @{$optional}, qw/config_file config_dir cfg / );
	my $cli_config = {};
	Getopt::Long::Configure( qw( default ) );
	my @options;

	#generate the value types and reference pointers required by GetOptions
	for my $key ( _explode_array( [ @{$required}, @{$optional} ] ) ) {
		push( @options, "$key=s" );
		push( @options, \$$cli_config{$key} );
	}

	#capture the arguments
	Getopt::Long::GetOptions( @options )
	  or confess( "Error in command line arguments : $!" );

	my $external_config = $self->config_file_dir( $cli_config );

	#hash::merge takes 'undef' as valid, which is not what we want when overwriting from config files
	for my $key ( keys( %{$cli_config} ) ) {
		delete( $cli_config->{$key} ) unless defined( $cli_config->{$key} );
	}

	my $return = Hash::Merge::merge( $external_config, $cli_config, $default_values );
	$self->check_config( $return, $required );

	return $return; #return!

}

#hit the default or explicit config with checks - useful when checks change after some condition
sub check_config {

	my ( $self, $href, $required ) = @_;
	$href ||= $self->cfg();
	unless ( ref( $href ) eq 'HASH' ) {
		confess( "Invalid href structure passed to check_config" );
	}

	for my $key ( @{$required} ) {
		THISKEY: {
			my $ref = ref( $key );

			#arrays in required mean 'one of'
			if ( $ref eq 'ARRAY' ) {
				warn "here";
				for my $subcheck ( @{$key} ) {

					if ( defined( $href->{$subcheck} ) ) {

						#all good - continue
						next THISKEY;
					}
				}
				confess( "None of [" . join( ',', @{$key} ) . "] provided through configuration" );
			} elsif ( $ref ) {

				confess( "Invalid reference [$ref] provided in check_config - can't parse" );
			} else {

				unless ( defined( $href->{$key} ) ) {
					confess( "$/Required key [$key] Not provided through configuration.$/$/" );
				}

				# 				warn "fine";

			}
		}
	}

}

sub config_file_dir {

	my ( $self, $c ) = @_;

	# if this fires, nothing is produced but no errors either
	$c ||= {};
	my $return      = {};
	my $dir_config  = $self->config_dir( $c->{config_dir} );
	my $file_config = $self->config_file( $c->{config_file} );
	$return = Hash::Merge::merge( $dir_config, $file_config );

	return $return; # return!
}

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

=head3 explode_array
	Turn arrays which may contain other arrays into a single stack of values
=cut

sub _explode_array {
	my ( $array ) = @_;
	my @return;
	for ( @{$array} ) {
		if ( ref( $_ ) ) {
			push( @return, explode_array( $_ ) );
		} else {
			push( @return, $_ );
		}
	}
	return @return;
}

1;
