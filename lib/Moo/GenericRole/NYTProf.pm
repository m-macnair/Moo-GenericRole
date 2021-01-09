use strict;

# ABSTRACT: use Devel::NYTProf consistently
package Moo::GenericRole::NYTProf;
our $VERSION = 'v1.0.3';
##~ DIGEST : f6d958cfdd43330e8fc231b9f476402c
use Moo;
use 5.006;
use warnings;

=head1 NAME
	~
=head1 VERSION & HISTORY
	<breaking revision>.<feature>.<patch>
	1.0.0 - <date>
		<actions>
	1.0.0 - <date unless same as above>
		The Mk1
=cut

=head1 SYNOPSIS
	TODO
=head2 TODO
	Generall planned work
=head1 ACCESSORS
=cut

ACCESSORS: {
	has nyt_profile_path => (
		is      => 'rw',
		lazy    => 1,
		default => sub { my ( $self ) = @_; return $self->make_profile_path( "./" ); }
	);

	# 0 not started, 1- running, 2 - done
	has nyt_profile_state => (
		is      => 'rw',
		lazy    => 1,
		default => sub { return 0 }
	);
	has skip_nyt_profile_to_html => (
		is      => 'rw',
		lazy    => 1,
		default => sub { return 0 }
	);
}

=head1 SUBROUTINES/METHODS
=head2 PRIMARY SUBS
	Main purpose of the module
=head3
=cut

sub start_nyt_profile {

	my ( $self, $params ) = @_;
	my $p_state = $self->nyt_profile_state();
	if ( $p_state == 0 ) {
		$self->nyt_profile_state( 1 );

		#if the path was set in the accessor explicitly
		my $path = $self->nyt_profile_path;
		$ENV{NYTPROF} = "subs=1:use_db_sub=1:file=$path";
		require Devel::NYTProf;
		Devel::NYTProf->import;
		require DB;
		DB::enable_profile( $path );
	} else {
		Carp::cluck( "Attempting to start profiling in profiling state $p_state" );
	}

}

sub finish_nyt_profile {

	my ( $self, $opt ) = @_;
	$opt ||= {};
	if ( $self->nyt_profile_state == 1 ) {
		DB::finish_profile();
		unless ( $self->skip_nyt_profile_to_html ) {
			my $odir = $self->nyt_profile_path;
			$odir =~ s|.nyt$|/|;
			$odir =~ s|/raw/|/zips/|;

			#to support changing user when running as apache or similar
			my $sudo = $opt->{sudo} || '';

			# process the db file produced into useful/readable html which would come out different if performed on other machines
			my $system_call = 'sleep 3'; # clears down thread backlog
			$system_call .= " && $sudo mkdir $odir && $sudo nytprofhtml -o $odir -f " . $self->profilepath() . ' 2>  /dev/null  > /dev/null ';
			my $tgz = $odir;
			$tgz =~ s|/$|.tgz|;
			$system_call .= " && $sudo tar -czf $tgz $odir $tonull";
			$system_call .= " && $sudo rm -Rf $odir $tonull";

			#warn "finish_nyt_profile system call : $system_call";
			system( $system_call);
		}
		$self->nyt_profile_state( 2 );
	} else {
		Carp::cluck( "Attempting to stop profiling in profiling state $p_state" );
	}

}

=head2 SECONDARY SUBS
=head3 make_profile_path
	
=cut

sub make_profile_path {

	my ( $self, $path ) = @_;
	$path ||= '';

	#':' not supported in file names
	$path .= "_" . $self->iso_time_string . '.nyt';
	$path =~ s|:|.|g;
	return $path;

}

=head2 WRAPPERS
=head3 external_function
=cut

=head1 AUTHOR
	mmacnair, C<< <mmacnair at cpan.org> >>
=head1 BUGS
	TODO Bugs
=head1 SUPPORT
	TODO Support
=head1 ACKNOWLEDGEMENTS
	TODO
=head1 COPYRIGHT
 	Copyright 2021 mmacnair.
=head1 LICENSE
	TODO
=cut

1;
