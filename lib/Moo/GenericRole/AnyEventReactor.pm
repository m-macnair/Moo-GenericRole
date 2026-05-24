# ABSTRACT : AnyEvent as a Moo Role
# Made with ChatGPT
package Moo::GenericRole::AnyEventReactor;
our $VERSION = 'v1.0.6';
##~ DIGEST : e2db245902c8cf09810398b38f9b0b21

use Moo::Role;
use AnyEvent;
use Socket qw(SOCK_STREAM);
use IO::Socket::UNIX;

# internal event loop condition variable
has _cv => (
	is      => 'lazy',
	builder => sub { AnyEvent->condvar },
);

# keep references to watchers alive
has _watchers => (
	is      => 'ro',
	default => sub { [] },
);

has socket_path => (
	is      => 'ro',
	default => sub { '/tmp/anyeventreactor.sock' },
);

has _server_fh => ( is => 'rw', );

has allowed_methods => (
	is      => 'rw',
	default => sub { [] }, # e.g. ['ping', 'cache_get']
);

has _dispatch => ( is => 'lazy', );

#TIL that accessors have inferred build methods when lazy
sub _build__dispatch {
	my $self = shift;

	my %map;

	for my $method ( @{$self->allowed_methods} ) {
		$map{$method} = $method
		  if $self->can( $method );
	}

	return \%map;
}

sub _setup {
	my $self = shift;

	# override in consuming class
}

sub run {
	my $self = shift;

	$self->_setup;

	print "[Reactor] starting event loop...\n";

	$self->_cv->recv;
}

sub add_timer {
	my ( $self, $after, $cb ) = @_;

	my $w = AnyEvent->timer(
		after => $after,
		cb    => sub {
			$cb->();

			# auto-remove timer reference
		}
	);

	push @{$self->_watchers}, $w;

	return $w;
}

sub add_interval {
	my ( $self, $interval, $cb ) = @_;

	my $w;

	$w = AnyEvent->timer(
		after    => $interval,
		interval => $interval,
		cb       => sub {
			$cb->();
		}
	);

	push @{$self->_watchers}, $w;

	return $w;
}

sub stop {
	my $self = shift;

	print "[Reactor] stopping...\n";

	$self->_watchers( [] );
	$self->_cv->send;
}

sub _start_ipc_server {
	my $self = shift;

	unlink $self->socket_path;

	my $server = IO::Socket::UNIX->new(
		Type   => SOCK_STREAM,
		Local  => $self->socket_path,
		Listen => 10,
	) or die "Cannot create socket: $!";

	$self->_server_fh( $server );

	print "[IPC] listening on ", $self->socket_path, "\n";

	$self->watch_io(
		$server, 'r',
		sub {
			my $client = $server->accept;
			return unless $client;

			$self->_handle_client( $client );
		}
	);
}

use JSON::MaybeXS;

sub _handle_client {
	my ( $self, $client ) = @_;

	my $json = <$client>;
	return unless defined $json;

	my $req = eval { decode_json( $json ) };

	my $res;

	if ( $@ ) {
		$res = {ok => 0, error => "invalid JSON"};
	} else {
		$res = $self->handle_request( $req );
	}

	print $client encode_json( $res ), "\n";
	close $client;
}

sub handle_request {
	my ( $self, $req ) = @_;

	my $cmd = $req->{cmd};

	unless ( defined $cmd ) {
		return {ok => 0, error => "missing cmd"};
	}

	my $dispatch = $self->_dispatch;

	my $method = $dispatch->{$cmd};

	unless ( $method ) {
		return {
			ok    => 0,
			error => "unknown or disabled command: $cmd",
		};
	}

	my $argv = $req; # pass full hashref through

	my $result;

	eval {
		$result = $self->$method( $argv );
		1;
	} or do {
		return {
			ok    => 0,
			error => "handler exception: $@",
		};
	};

	return $result;
}

sub ping {
	return {ok => 1, pong => time};
}

sub watch_io {
	my ( $self, $fh, $mode, $cb ) = @_;

	my $w = AnyEvent->io(
		fh   => $fh,
		poll => $mode,
		cb   => $cb,
	);

	push @{$self->_watchers}, $w;

	return $w;
}

1;

