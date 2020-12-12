# ABSTRACT : perform and preserve command line interaction
package Moo::GenericRole::CombinedCLI;
our $VERSION = 'v1.2.6';
##~ DIGEST : 96777d764158613c33f033ff0a5eed14

require Getopt::Long;
require Config::Any::Merge;
require Hash::Merge;
use Carp;
use Moo::Role;
with qw/Moo::GenericRole/;

after new => sub {
	my ( $self ) = @_;
	$self->_verify_methods( [qw/sub_on_directory_files /] );
};

sub get_config {

	my $self = shift;
	my $cfg  = $self->get_combined_config( @_ );

	# in Common::Core now
	$self->cfg( $cfg );

}

# TODO pure href driven version

=head3 get_combined_config
	given an arref of required, an arref of optional with some defaults and a href of optional switches, generate a configuration href which does what I expect it to do
=cut

sub get_combined_config {

	my ( $self, $required, $optional, $p ) = @_;

	$required ||= [];
	$optional ||= [];
	$p        ||= {};

	#always support help as a flag
	push( @{$p->{flags}}, 'help' );
	my $default_values = $p->{'default'} || {};

	push( @{$optional}, qw/config_file config_dir cfg help / );

	my $cli_values = $self->get_cli_values( $required, $optional, $p );

	my $external_config = $self->config_file_dir( $cli_values );

	#hash::merge takes 'undef' as valid, which is not what we want when overwriting from config files
	for my $key ( keys( %{$cli_values} ) ) {
		delete( $cli_values->{$key} ) unless defined( $cli_values->{$key} );
	}

	if ( $cli_values->{help} || ( @{$required} && @ARGV == 0 ) ) {
		print "No required fields provided! " if ( @{$required} && @ARGV == 0 );
		print "Usage:";
		print $self->format_usage( $p->{required}, $p->{optional} );
		exit;
	} else {

		#overwrite hard coded defaults with configuration file(s)
		my $return = Hash::Merge::merge( $default_values, $external_config );

		#overwrite the above with explicit command line settings
		$return = Hash::Merge::merge( $return, $cli_values );

		#fitch a pit if a required field is missing
		eval { $self->check_config( $return, $required ); } or do {
			my $error = $@ || 'Unknown failure';
			print "$/### Final configuration did not provide a required value ! ###";
			print $self->format_usage( $p->{required}, $p->{optional} );
			print "[$error]";
			exit;
		};

		return $return; #return!
	}
}

sub get_cli_values {
	my ( $self, $required, $optional, $p ) = @_;

	$required ||= [];
	$optional ||= [];
	$p        ||= {};

	my $cli_values = {};
	my @options;

	#generate the value types and reference pointers required by GetOptions
	for my $key ( _explode_array( [ @{$required}, @{$optional} ] ) ) {

		#expensive, but what the hey
		#without a data type (which sensibleness suggests should always be a string anyway) , the key is considered a flag
		if ( grep( /^$key$/, @{$p->{flags}} ) ) {
			push( @options, "$key" );
		} else {
			push( @options, "$key=s" );
		}
		push( @options, \$$cli_values{$key} );
	}

	#capture the arguments to command line separately
	my $array = [@ARGV];

	#permit multiple runs
	Getopt::Long::Configure( 'pass_through' );
	Getopt::Long::GetOptionsFromArray( $array, @options );
	return $cli_values;

}

#stolen from massh2.pl

sub prompt_for {
	my ( $self, $prompt, $default, $opt ) = @_;

	$opt ||= {};
	my $promptstring = $prompt;
	$promptstring .= " [$default]" if $default;
	$promptstring .= ' :';
	require Term::ReadKey;
	while ( 1 ) {
		print $promptstring;
		$| = 1; #flush
		Term::ReadKey::ReadMode( 'noecho' ) if $opt->{hidden};
		my $res = Term::ReadKey::ReadLine( 0 );
		if ( $opt->{hidden} ) {
			print $/;
			Term::ReadKey::ReadMode( 'restore' );
		}
		chomp( $res );
		$res = $res || $default;
		return $res if $res;
		print "$/must provide a value$/" unless $opt->{optional};
	}

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
				for my $subcheck ( @{$key} ) {

					if ( defined( $href->{$subcheck} ) ) {

						#all good - continue
						next THISKEY;
					}
				}
				confess( "None of [ Required ] keys [" . join( ',', @{$key} ) . "] provided!" );
			} elsif ( $ref ) {

				confess( "Invalid reference [$ref] provided in check_config - can't parse!" );
			} else {

				unless ( defined( $href->{$key} ) ) {
					confess( qq{[ Required ] key "-$key" is missing!$/$/} );
				}

				# 				warn "fine";

			}
		}
	}

	return 1;

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
			push( @return, _explode_array( $_ ) );
		} else {
			push( @return, $_ );
		}
	}
	return @return;
}

sub usage_string {
	my ( $self, $p ) = @_;
	my $string;
	if ( $p->{usage} ) {
		$string .= "Usage :$/$/$p->{usage}$/";
	} else {
		$string .= "No usage details available.";
	}
	return $string;
}

sub builtin_cli_usage {
	return {
		config_dir  => "Path to a directory containing any number of configuration files readable by Config::Any.$/\t\t\tOverwritten by contents of -config_file if present, and explicit command line options.",
		config_file => "Path to a configuration file readable by Config::Any.$/\t\t\tOverwritten by explicit command line options.",
		cfg         => "-config_file with fewer keystrokes.",
		help        => "Show usage."
	};
}

# TODO unify tab stops
sub format_usage {
	my ( $self, $required, $optional ) = @_;
	my $string;
	$string .= "$/$/";

	if ( $required && %{$required} ) {
		$string .= "[ Required ]$/$/";
		$string .= $self->format_usage_hrefs( $required );
		$string .= "$/$/";
	}

	#$/[optional] is read as an arref

	$string .= "[ Optional ] $/$/";
	$string .= $self->format_usage_hrefs( $optional ) if ( $optional && %{$optional} );
	$string .= $self->format_usage_hrefs( $self->builtin_cli_usage() );
	$string .= "$/$/";

	return $string;

}

sub format_usage_hrefs {
	my ( $self, $href ) = @_;
	my $string = '';
	for my $key ( sort( keys( %{$href} ) ) ) {
		$string .= "-$key\t:\t$href->{$key}$/";
	}
	return $string;
}

1;
