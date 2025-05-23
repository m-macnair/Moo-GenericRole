# ABSTRACT: Common file system tasks
package Moo::GenericRole::FileSystem;

our $VERSION = 'v1.4.4';
##~ DIGEST : f3cfbac95af49f413f6da4984105742d

use Moo::Role;
with qw/Moo::GenericRole/;
use Carp qw/croak confess cluck/;
ACCESSORS: {

	has tmp_dir => (
		is      => 'rw',
		lazy    => 1,
		default => sub {
			my ( $self ) = @_;

			$self->clean_path( $self->build_tmp_dir() );
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

=head3 init_tmp_dir
	In most cases, we want ./<something descriptive>/<something unique> which messing with temp_root doesn't provide
	so use the argument here as the root and do everything else as normal
=cut

sub init_tmp_dir {
	my ( $self, $root ) = @_;
	$root = $self->abs_path( $root );
	$self->make_path( $self->tmp_root( $root ) );
	return $self->tmp_dir();
}

#get a unique temporary directory path string
sub build_tmp_dir_path {

	#tested
	my ( $self, $root ) = @_;
	$root ||= $self->tmp_root();
	return $self->clean_path( $self->build_time_path( $root ) );

}

#create a unique temporary directory tree
sub build_tmp_dir {

	#tested

	my ( $self, $root ) = @_;
	$root ||= $self->tmp_root();
	my $path = $self->build_tmp_dir_path( $root );

	$self->make_path( $path );
	return $path;

}

sub check_path {

	#tested
	my ( $self, $path, $value_name ) = @_;

	# 	$path = qq|"$path"|;
	$value_name = _value_name( $value_name );
	confess( "check_path $value_name" . "value is null!$/\t" )                unless $path;
	confess( "check_path $value_name" . "path [$path] does not exist!$/\t" )  unless -e $path;
	confess( "check_path $value_name" . "path [$path] is not readable!$/\t" ) unless -r $path;
}

sub check_file {
	my ( $self, $path, $value_name ) = @_;

	$self->check_path( $path, $value_name );

	# 	$path = qq|"$path"|;
	$value_name = _value_name( $value_name );
	confess( "checkfile $value_name" . "path [$path] is not a file!$/\t" ) unless -f $path;

}

sub check_dir {
	my ( $self, $path, $value_name ) = @_;

	$value_name = _value_name( $value_name );
	$self->check_path( $path, $value_name );

	# 	$path = qq|"$path"|;
	confess( "check_dir $value_name" . "path [$path] is not a directory!$/\t" ) unless -d $path;

}

#reduce noise by ensuring the optional path value name (e.g. 'output file' ) is defined
sub _value_name {
	my ( $value_name ) = @_;
	if ( $value_name ) {
		return "[$value_name] ";
	} else {
		return '';
	}
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
	File::Copy::mv( $source, $target ) or confess( "move failed: $!$/\t" );
	return 1;

}

=head3 safe_mvf
	Move a file or else - in that it'll try and do everything what needs doing otherwise
=cut 

sub safe_mvf {
	my $self = shift;
	my ( $source, $target, $opt ) = $self->_shared_fc( @_ );

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

	my $new_path = $self->get_safe_path( $target, {fatal => 1, %{$opt}} );

	require File::Copy;
	File::Copy::mv( $source, $target_dir || $target )
	  or confess( "move failed: $!$/" );
	return $new_path;
}

# as above, but copy
sub safe_cpf {
	my $self = shift;
	my ( $source, $target, $opt ) = $self->_shared_fc( @_ );

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
	my $result = $self->get_safe_path( $target, {fatal => 1, %{$opt}} );

	require File::Copy;
	File::Copy::cp( $source, $target_dir || $target )
	  or confess( "move failed: $!$/" );
	return $result;
}

=head3 safe_mvd
	Move a directory or else - in that it'll try and do everything what needs doing otherwise
=cut 

sub safe_mvd {
	my $self = shift;
	my ( $source, $target, $opt ) = $self->_shared_fc( @_ );
	die "not supported yet";

}

=head3 safe_duplicate_path
	get_duplicate_safe_path because safe_duplicate_path could be ambiguously interpretted when i'm half asleep
=cut 

sub safe_duplicate_path {
	require Carp;
	Carp::cluck( "Obsolete method name" );
	my $self = shift;
	$self->get_safe_path( @_ );

}

=head3 get_safe_path
	Given a path, return the path or a path that can be confidently used instead, e.g. won't create a duplicate and is Windows proof
=cut

sub get_safe_path {

	#tested
	my $self = shift;
	my ( $path, $p ) = @_;

	$p ||= {};
	if ( -e $path ) {

		#tested
		confess( "Target [$path] already exists$/\t" ) if $p->{fatal};

		my ( $name, $dir, $suffix ) = $self->file_parse( $path );

		#tested
		#feasibly this should come from UUID role, but this keeps it more self contained
		require Data::UUID;
		my $ug   = Data::UUID->new;
		my $uuid = $ug->to_string( $ug->create() );

		# TODO sprintf?
		my $newpath = "$dir/$name\_$uuid$suffix";

		cluck( "Target [$path] already exists, renamed to $newpath$/\t" ) if $p->{verbose} || $self->can( 'verbose' ) && $self->verbose();

		$path = $newpath;
	}
	return $path;

}

sub clean_path {
	my ( $self, $path ) = @_;
	if ( -e $path && -d $path ) {
		$path = "$path/";
	}
	$path =~ s|//+|/|g;
	return $path;
}

=head3 file_parse
	The only reason I've ever used File::Basename - split a path into the file name, it's path and it's .suffix
=cut

sub file_parse {
	my ( $self, $path ) = @_;
	require File::Basename;
	my ( $name, $dir, $suffix ) = File::Basename::fileparse( $path, qr/\.[^.]*/ );
	return ( $name, $dir, $suffix );
}

=head3 percent_file_name
	Fat32 (and others) don't play well with utf8 file names, so un-fancify them
=cut

sub percent_file {

	my ( $self, $path ) = @_;
	my ( $name, $dir, $suffix ) = $self->file_parse( $path );
	require URI::Escape;
	$name = URI::Escape::uri_escape_utf8( $name );
	return "$dir/$name$suffix";
}

sub snake_file {
	my ( $self, $path ) = @_;
	my ( $name, $dir, $suffix ) = $self->file_parse( $path );
	$name =~ s| |_|g;
	return "$dir/$name$suffix";

}

sub snake_percent_file {

	my ( $self, $path ) = @_;
	my ( $name, $dir, $suffix ) = $self->file_parse( $path );
	$name =~ s| |_|g;
	require URI::Escape;
	$name = URI::Escape::uri_escape_utf8( $name );
	return "$dir/$name$suffix";
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
	$root = $self->abs_path( $root );
	return $self->build_time_path( $root, 'Object Temporary Directory' );

}

sub _shared_fc {
	my ( $self, $source, $target, $opt ) = @_;

	$opt ||= {};
	$source = $self->abs_path( $source );

	$target = $self->abs_path( $target );
	return ( $source, $target, $opt );
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
			require Data::Dumper;
			my $errstr;
			for ( @{$errors} ) {
				$errstr .= Data::Dumper::Dumper( $_ ) . $/;
			}
			confess( "[$path] creation failed : [$/$errstr]$/\t" );
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

sub make_paths {
	my ( $self, $paths ) = @_;
	confess( "Not an arref of paths?$/" ) unless ref( $paths ) eq 'ARRAY';
	for my $path ( @{$paths} ) {
		$self->make_path( $path );
	}
	return 1;

}

=head3 sub_on_find_files

	Given a sub and a directory, pass the sub each file in the directory and subdirectories until the sub returns falsey, then jump out of the search

=cut

sub sub_on_find_files {

	#tested
	my ( $self, $sub, $directory, $find_opts, $p ) = @_;
	$find_opts ||= {};
	$p         ||= {};
	confess( "First parameter to sub_on_find_files was not a code reference$/\t" )                                                     unless ref( $sub ) eq 'CODE';
	confess( "Second parameter [" . ( defined( $directory ) ? $directory : '' ) . "] to sub_on_find_files was not a valid directory" ) unless $directory && -d $directory;
	$self->check_dir( $directory );
	require File::Find;
	File::Find::find(
		{
			wanted => sub {
				return if ( -d $File::Find::name );
				return unless ( $self->is_a_file( $File::Find::name ) );
				my $full_path = $self->abs_path( $File::Find::name );

				goto Moo_GenericRole_FileSystem_sub_on_find_files_end unless ( &$sub( $full_path, $File::Find::name ) );
			},
			no_chdir => 1,
			%{$find_opts}
		},
		$directory
	);

	Moo_GenericRole_FileSystem_sub_on_find_files_end:
	return;

}

=head3 sub_on_directory_files2

	Given a sub and a directory, 
	pass the sub each file in the directory 
	but NOT the subdirectories 
	until the sub returns falsey, then jump out of the loop
=cut

sub sub_on_directory_files {
	my ( $self, $sub, $directory ) = @_;
	confess( "First parameter to sub_on_directory_files was not a code reference$/\t" )                                                     unless ref( $sub ) eq 'CODE';
	confess( "Second parameter [" . ( defined( $directory ) ? $directory : '' ) . "] to sub_on_directory_files was not a valid directory" ) unless $directory && -d $directory;

	for my $file ( glob qq<"$directory"/*> ) {
		next if ( -d $file );
		next unless ( $self->is_a_file( $file ) );
		my $full_path = $self->abs_path( $file );
		last unless ( &$sub( $full_path ) );
	}
	return;
}

sub check_softlink_file {
	my ( $self, $path ) = @_;
	if ( -l $path ) {
		my $link_path = readlink( $path );

		# 		warn $link_path;
		if ( -f $link_path ) {
			return 1;
		}
	}
	return;
}

sub is_a_file {
	my ( $self, $path ) = @_;
	return -f $path || $self->check_softlink_file( $path );
}

=head3 abs_path
	Cwd::abs_path does Strange Things when the path in question doesn't exist; this way provides 'do the thing I want regardless' 
=cut

sub abs_path {

	#tested
	my $self = shift;
	my ( $path ) = @_;
	my $return;
	if ( $path && -e $path ) {
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

sub get_hashes_for_file {
	my ( $self, $path ) = @_;

	$path = $self->abs_path( $path );
	my $md5_cmd  = qq<md5sum "$path" | awk '{ print \$1 }'>;
	my $sha1_cmd = qq<sha1sum "$path" | awk '{ print \$1 }'>;
	my $ed2k_cmd = qq<ed2k_hash "$path" >;

	my $md5_sum  = `$md5_cmd`;
	my $sha1_sum = `$sha1_cmd`;
	my $ed2k_sum = `$ed2k_cmd`;

	my $size;
	chomp( $md5_sum, $sha1_sum, $ed2k_sum );
	my @ed2k = split( '\|', $ed2k_sum );

	$size     = $ed2k[3];
	$ed2k_sum = $ed2k[4];

	return {
		path => $path,
		size => $size,
		md5  => lc( $md5_sum ),
		sha1 => lc( $sha1_sum ),
		ed2k => lc( $ed2k_sum )
	};
}

=head3 glob_paths
	Return arref of paths matching command line style *.* matches
	There's a case to be made that "./" should be auto-prepended in certain situations, but not today
	'require' used here not just for TTek style paranoia, but because the glob method overwrites the default version
=cut

sub glob_paths {
	my ( $self, $match_string ) = @_;

	#in the case where * wasn't used and we only want one file
	if ( -f $match_string ) {
		return [$match_string];
	}

	#in the case where * or similar was used and we want everything
	require File::DosGlob;
	return [ File::DosGlob::glob( $match_string ) ];

}

sub make_dirs {
	my ( $self, $root, $folder_arref, $p ) = @_;
	$p ||= {};
	for my $folder ( @{$folder_arref} ) {
		my $new = "$root/$folder";
		unless ( -d $new ) {
			mkdir( $new ) or die $!;
		}
	}
}

1;
