#ABSTRACT : Do common things with LinuxINotify2 - specifically monitoring files for read/write and close
# Made with ChatGPT, adapted manually
package Moo::GenericRole::FileIO::LinuxInotify2;
use strict;
use warnings;

our $VERSION = 'v0.0.3';
##~ DIGEST : 7eda6ea8f0442024084c18d685880ab7

use Moo::Role;
use Carp;
use Linux::Inotify2;
use Time::HiRes qw(time sleep);

sub get_new_watcher {
	my $inotify = new Linux::Inotify2
	  or die "unable to create new inotify object: $!";
	return $inotify;
}

# hold up execution until the $path provided has IN_CLOSE event on it

sub wait_for_file_close {
	my ( $self, $path, $p ) = @_;
	die "invalid path [$path]" unless -f $path;
	$p ||= {};
	$p->{timeout} ||= 30;
	my $mask = Linux::Inotify2::IN_CLOSE_WRITE()

	  #| Linux::Inotify2::IN_CLOSE_READ()
	  | Linux::Inotify2::IN_CLOSE_NOWRITE();
	my $event_info;
	my $inotify_obj = $self->get_new_watcher();
	$inotify_obj->watch(
		$path, $mask,
		sub {
			my $e = shift;
			$event_info = {
				path => $e->fullname,
				mask => $e->mask,
				name => $e->name,

				write   => $e->IN_CLOSE_WRITE   ? 1 : 0,
				nowrite => $e->IN_CLOSE_NOWRITE ? 1 : 0,
			};
		}
	);

	my $start = time;
	while ( 1 ) {
		$inotify_obj->poll;
		last if $event_info;

		if ( $p->{timeout} && ( time - $start ) > $p->{timeout} ) {
			print "Timeout [$p->{timeout}] reached while waiting for close event on path [$path]\n";
			last;
		}

		sleep 0.1;
	}

	my $return = {event_info => $event_info,};
	if ( $event_info->{write} ) {
		$return->{pass} = 'write';
	}
	if ( $event_info->{nowrite} ) {
		$return->{pass} = 'nowrite';
	}

	return $return;
}

1;

