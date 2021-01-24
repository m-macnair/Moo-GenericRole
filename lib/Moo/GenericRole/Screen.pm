use strict;

# ABSTRACT: interact with gnu screen
package Moo::GenericRole::Screen;
our $VERSION = 'v1.0.8';
##~ DIGEST : 83fc49e09c138a699262684a4e224e2d
use Moo::Role;
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
	has running_screen_map => (
		is      => 'rw',
		default => sub { return {} }
	);
}

=head1 SUBROUTINES/METHODS
=head2 PRIMARY SUBS
	Main purpose of the module
=head3 run_on_min_screens
	Given a sub which returns a shared value, a command sub that returns a shell command when it processes that value, and some non defaults, run commands in parralel until there are none left
=cut

sub run_on_min_screens {

	my ( $self, $get_value_sub, $get_command_sub, $c ) = @_;
	die "Not a valid get_value_sub"   unless ( ref( $get_value_sub ) ) eq 'CODE';
	die "Not a valid get_command_sub" unless ( ref( $get_command_sub ) ) eq 'CODE';
	$c                ||= {};
	$c->{sleep_time}  ||= 5;
	$c->{min_screens} ||= 5;

	#Get the first command value to start the loop
	my $command_value = &$get_value_sub( $c );
	while ( 1 ) {
		my $res = $self->_run_on_min_screens_loop_iteration( \$command_value, $get_value_sub, $get_command_sub, $c );

		#work left and either at capacity or just added a screen
		if ( index( $res, 'work' ) == 0 ) {
			if ( index( $res, '_new_screen' ) != -1 ) {

				#new screen but we still have work to allocate, so jump straight back into allocation
			} else {
				sleep( $c->{sleep_time} );
			}

			#screens still running, no work left
		} elsif ( $res eq 'done_work_running_screen' ) {
			sleep( $c->{sleep_time} );
		} elsif ( $res eq 'done_work_finished' ) {

			#done
			return 1;
		}

	}

}

=head3 _run_on_min_screens_loop_iteration
	Split out for when I can figure out how to make it interactive
=cut

sub _run_on_min_screens_loop_iteration {

	my ( $self, $command_value, $get_value_sub, $get_command_sub, $c ) = @_;
	my $running_screen_count = $self->check_running_screens();

	#determine if there is work left to be done
	my $return;
	if ( defined( $$command_value ) ) {
		$return = 'work';
	} else {
		$return = 'done_work';
	}

	# 	warn $running_screen_count;

	#determine if running at screen capacity and if not, load work
	if ( $running_screen_count < $c->{min_screens} ) {
		if ( $return eq 'work' ) {

			#easy mistake to make - must provide a screen naming root
			my ( $screen_name_root, $command_string ) = &$get_command_sub( $$command_value, $c );
			die "command_string not provided by get_command_sub" unless $command_string;

			# 			warn $command_string;
			$self->run_task_on_new_screen( $screen_name_root, $command_string );

			#load next command for the next free screen, must return undef when data source is exhausted
			$$command_value = &$get_value_sub( $c );
			$return .= '_new_screen';
		} elsif ( $running_screen_count ) {

			#There is no work left but screens are still running with incomplete work
			$return .= '_running_screen';
		} else {

			#we're done here
			$return .= '_finished';
		}
	} else {

		#There is work left, but screens at capacity
		if ( $return eq 'work' ) {
			if ( $running_screen_count > $c->{min_screens} ) {
				$return .= '_over_capacity';
			} else {
				$return .= '_full_screen';
			}
		} else {

			#we're done here
			$return .= '_finished';
		}
	}
	return $return;

}

# TODO - had enough for one day
sub kill_running_screens {
	my ( $self, $map ) = @_;

}

=head2 SECONDARY SUBS
	Actions used by one or more PRIMARY SUBS that aren't wrappers
=head3 check_running_screens
	return how many screens in a given map are still running
=cut

sub check_running_screens {

	my ( $self, $map ) = @_;
	$map ||= $self->running_screen_map();

	my $running_count = 0;
	for my $screen_name ( sort ( keys( %{$map} ) ) ) {
		if ( $self->check_for_screen_name( $screen_name ) ) {
			$running_count++;
		} else {
			delete( $map->{$screen_name} );
		}
	}

	return ( $running_count );

}

=head3 run_task_on_new_screen
	given a screen name root and a task, run the command on its own screen and return the auto-generated identifier
=cut

sub run_task_on_new_screen {

	my ( $self, $name_string, $task_string ) = @_;
	require Data::UUID;
	my $ug          = Data::UUID->new;
	my $uuid        = lc( $ug->create_str() );
	my $screen_name = "$name_string\_$uuid";
	my $cstring     = qq{screen -S $screen_name -d -m  bash -c "$task_string"};
	print `$cstring`;
	$self->running_screen_map->{$screen_name} = 1;
	return ( $screen_name, $cstring );

}

=head3 check_for_screen_name
	as named; could be more robust?
=cut

sub check_for_screen_name {

	my ( $self, $screen_name ) = @_;
	my $res = `screen -ls $screen_name`;
	if ( index( $res, '1 Socket in ' ) != -1 ) {
		return 1;
	}
	return;

}

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
