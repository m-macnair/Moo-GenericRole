# ABSTRACT : perform and preserve command line interaction
package Moo::GenericRole::CombinedCLI;
our $VERSION = 'v1.3.2';
##~ DIGEST : 188f68aa23d55eb1b6ab164e1ae92d7c

require Getopt::Long;
require Config::Any::Merge;

#needs to be a use in Ubuntu (!?)
use Hash::Merge;
use Carp;
use Moo::Role;
with qw/
  Moo::GenericRole
  Moo::GenericRole::ConfigAny
  /;

after new => sub {
	my ( $self ) = @_;
	$self->_verify_methods( [qw/sub_on_directory_files /] );
};

sub get_config {

	my $self = shift;
	my $cfg  = $self->get_combined_config( @_ );

	# in Common::Core now
	$self->cfg( $cfg );
	return $cfg;

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

#TODO handle overlapping shorthand keys correctly ; -config -> config_dir and config_file doesn't work the way you think it does r/n

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

=head3 splice_glob_argv
	Different enough from FileSystem's glob_paths:
		given number of arguments, extract that many arguments from the @ARGV variable, and return the rest as an array - with the assumption that it's caused by glob expansion
		No clue how this would interact with get_config
=cut

sub splice_glob_argv {
	my ( $self, $elements, $aref ) = @_;
	$elements ||= 0;
	$aref     ||= [@ARGV];
	my @extract = splice( @{$aref}, 0, $elements );
	return ( @extract, $aref );
}

1;
