#ABSTRACT:  do pid files - ideally with wrappers around main() calls
package Moo::GenericRole::PID;
our $VERSION = 'v1.0.10';
##~ DIGEST : 376fec5a1780957fe83f83c3d5774125

use Moo::Role;
with qw/Moo::GenericRole/;
ACCESSORS: {
	has pid_root => (
		is      => 'rw',
		lazy    => 1,
		default => sub { "$ENV{HOME}" }
	);
	has pid_path => (
		is      => 'rw',
		lazy    => 1,
		default => sub { $_[0]->pid_root . '/.pid_' . $$ }
	);
}

sub startpid {

	my ( $self ) = @_;
	open( my $fh, '>', $self->pid_path() );
	print $fh time;
	close $fh;

}

sub stoppid {

	my ( $self ) = @_;
	unlink $self->pid_path();

}
1;
