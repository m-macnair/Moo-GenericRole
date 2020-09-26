# ABSTRACT: Common file system tasks
package Moo::GenericRole::FileSystem;
our $VERSION = 'v1.0.15';
##~ DIGEST : 5dd67eb9994b12973d21c0dcd4989472

use Moo::Role;
with qw/Moo::GenericRole/;

use POSIX;
use Data::UUID;
ACCESSORS: {

	has tmp_dir => (
		is      => 'rw',
		lazy    => 1,
		default => sub {
			my ( $self ) = @_;
			$self->build_tmp_dir();
		}
	);

	has tmp_root => (
		is      => 'rw',
		lazy    => 1,
		default => sub {
			return "$ENV{HOME}/tmp/";
		}
	);
}

#get a unique temporary directory path
sub build_tmp_dir_path {

	#tested
	my ( $self, $root ) = @_;
	$root ||= $self->tmp_root();
	return $self->build_time_path( $root );

}

#create a unique temporary directory tree
sub build_tmp_dir {

	#tested

	my ( $self, $root ) = @_;
	my $path = $self->build_tmp_dir_path( $root );
	$self->make_path( $path );
	return $path;

}

sub check_path {

	#tested
	my ( $self, $path, $value_name ) = @_;
	$value_name = _value_name( $value_name );
	confess( "check_path $value_name value is null" )                 unless $path;
	confess( "check_path $value_name path [$path] does not exist" )   unless -e $path;
	confess( "check_path $value_name path [$path] is not readable " ) unless -r $path;
}

sub check_file {
	my ( $self, $path, $value_name ) = @_;
	$value_name = _value_name( $value_name );
	$self->check_path( $path, $value_name );
	confess( "checkfile $value_name path [$path] is not a file " ) unless -f $path;

}

sub check_dir {
	my ( $self, $path, $value_name ) = @_;
	$value_name = _value_name( $value_name );
	$self->check_path( $path, $value_name );
	confess( "check_dir $value_name path [$path] is not a directory " ) unless -d $path;

}

#reduce noise by ensuring the optional path value name (e.g. 'output file' ) is defined
sub _value_name {
	my ( $value_name ) = @_;
	unless ( $value_name ) {
		$value_name = '';
	}
	return $value_name;
}

#"do the only thing I ever use File::Spec for"
sub file_path_parts {
	my ( $self, $path ) = @_;
	require File::Spec;
	my ( $dev, $dir, $file ) = File::Spec->splitpath( $path );
	return ( $file, $dir, $dev );
}

#because I can't be fussed doing the require every single time
sub mvf {
	my $self = shift;
	my ( $source, $target ) = $self->_shared_fc( @_ );
	require File::Copy;
	File::Copy::mv( $source, $target ) or confess( "move failed: $!" );
	return 1;

}

=head3 safemvf
	Move a file or else - in that it'll try and do everything what needs doing otherwise
=cut 

sub safe_mvf {
	my $self = shift;
	my ( $source, $target ) = $self->_shared_fc( @_ );

	#HCF if we're trying to move nothing
	$self->check_file( $source );
	my $target_dir;

	require File::Basename;

	#Handle moving a file to a directory without an explicit file name
	if ( -d $target ) {
		my ( $name, $dir ) = File::Basename::fileparse( $source );
		$target = "$target/$name";
	} else {

		my ( $name, $target_dir ) = File::Basename::fileparse( $target );

		#does nothing if target directory exists already
		$self->make_path( $target_dir );
		$target = "$target_dir/$name";
	}

	#HFC if we're trying to overwrite
	$self->safe_duplicate_path( $target, {fatal => 1} );

	require File::Copy;
	File::Copy::mv( $source, $target_dir || $target )
	  or confess( "move failed: $!" );
	return 1;
}

sub safe_duplicate_path {

	#tested
	my $self = shift;
	my ( $path, $c ) = @_;

	$c ||= {};
	if ( -e $path ) {

		#tested
		confess( "Target [$path] already exists" ) if $c->{fatal};
		require File::Basename;
		my ( $name, $dir, $suffix ) = File::Basename::fileparse( $path, qr/\.[^.]*/ );

		#tested
		#feasibly this should come from UUID role, but this keeps it more self contained
		require Data::UUID;
		my $ug   = Data::UUID->new;
		my $uuid = $ug->to_string( $ug->create() );

		# TODO sprintf?
		my $newpath = "$dir/$name\_$uuid$suffix";

		cluck( "Target [$path] already exists, renamed to $newpath" ) if $c->{verbose} || $self->verbose();

		return $newpath;
	}
	return $path;

}

=head3 build_time_path
	Build a full, UUID unique directory path with an iso time stamp 
=cut

sub build_time_path {

	#tested
	my ( $self, $root, $value_name ) = @_;
	$self->check_dir( $root, $value_name );
	require Data::UUID;
	require POSIX;
	my $ug      = Data::UUID->new;
	my $uuid    = lc( $ug->create_str() );
	my $tmppath = POSIX::strftime( "/%Y-%m-%d/%H/%M:%S/", gmtime() );

	return $self->abs_path( "$root/$tmppath/$uuid/" );
}

sub _build_tmp_dir {

	#tested
	my ( $self, $root ) = @_;
	$root ||= './';
	$root = abs_path( $root );
	return $self->build_time_path( $root, 'Object Temporary Directory' );

}

sub _shared_fc {
	my ( $self, $source, $target ) = @_;
	$source = $self->abs_path( $source );
	$target = $self->abs_path( $target );
	return ( $source, $target );
}

sub make_path {

	#tested
	my ( $self, $path ) = @_;
	confess( "Path missing" ) unless $path;
	my $exists;

	#create unless exists

	if ( -d $path ) {
		$exists = 1;
	} else {
		$exists = 0;
		require File::Path;
		my $errors;
		File::Path::make_path( $path, {error => \$errors} );
		if ( $errors && @{$errors} ) {
			my $errstr;
			for ( @{$errors} ) {
				$errstr .= $_ . $/;
			}
			confess( "[$path] creation failed : [$/$errstr]$/" );
		}
	}

	#it's possible the path will be a string concat; so return the actual path at the end
	if ( wantarray() ) {

		#there's a chance that 'already exists' is important for a concatenated path , so when a capture for that is present, fill it with previously existed state
		return ( $path, $exists );
	} else {

		return $path;
	}

}

sub sub_on_directory_files {

	#tested
	my ( $self, $sub, $directory ) = @_;
	confess( "First parameter to subonfiles was not a code reference" ) unless ref( $sub ) eq 'CODE';
	$self->check_dir( $directory );
	require File::Find;
	OUTERFIND: {

		File::Find::find(
			{
				wanted => sub {
					return unless -f $File::Find::name;
					my $full_path = $self->abs_path( $File::Find::name );
					last OUTERFIND unless ( &$sub( $full_path ) );
				},
				no_chdir => 1,
			},
			$directory
		);
	}
}

=head3 abs_path
	Cwd::abs_path does Strange Things when the path in question doesn't exist; this way provides 'do the thing I want regardless' 
=cut

sub abs_path {

	#tested
	my $self = shift;
	my ( $path ) = @_;
	my $return;
	if ( -e $path ) {
		require Cwd;
		$return = Cwd::abs_path( $path );
		if ( -d $return ) {
			$return .= '/';
		}
	} else {
		require File::Spec;
		$return = File::Spec->rel2abs( $path );
	}
	return $return; #return!

}

1;
