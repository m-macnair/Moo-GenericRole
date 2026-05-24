# ABSTRACT : AnyEvent client as a Moo Role
# Made with ChatGPT
package Moo::GenericRole::AnyEventSocketClient;
our $VERSION = 'v1.0.1';
##~ DIGEST : 5eaa9dc885ddab28c324ea7740461bdf

use Moo::Role;

use IO::Socket::UNIX;
use JSON::MaybeXS;
use Carp qw(croak);
use Socket;

# -----------------------------
# Configuration
# -----------------------------

has socket_path => (
	is      => 'ro',
	default => sub { '/tmp/anyeventreactor.sock' },
);

# -----------------------------
# Core IPC call
# -----------------------------

sub call {
	my ( $self, $payload ) = @_;

	croak "call expects a hashref payload"
	  unless ref $payload eq 'HASH';

	my $sock = IO::Socket::UNIX->new(
		Type => SOCK_STREAM(),
		Peer => $self->socket_path,
	) or croak "Cannot connect to socket ($self->{socket_path}): $!";

	my $json = encode_json( $payload );

	print $sock $json . "\n";

	my $response = <$sock>;

	close $sock;

	return defined $response ? decode_json( $response ) : {ok => 0, error => "no response from server"};
}

# -----------------------------
# Convenience methods
# -----------------------------

sub cmd {
	my ( $self, $cmd, $args ) = @_;

	$args //= {};

	croak "command must be defined"
	  unless defined $cmd;

	return $self->call(
		{
			cmd => $cmd,
			%$args,
		}
	);
}

sub ping {
	my $self = shift;

	return $self->call(
		{
			cmd => 'ping',
		}
	);
}

sub cache_get {
	my ( $self, $key ) = @_;

	return $self->call(
		{
			cmd => 'cache_get',
			key => $key,
		}
	);
}

sub cache_set {
	my ( $self, $key, $value ) = @_;

	return $self->call(
		{
			cmd   => 'cache_set',
			key   => $key,
			value => $value,
		}
	);
}

# -----------------------------
# End of role
# -----------------------------

1;
