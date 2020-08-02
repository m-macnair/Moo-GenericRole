use strict; # applies to all packages defined in the file

package Moo::GenericRole::AWS::Paws::S3;
our $VERSION = 'v1.0.2';

##~ DIGEST : 9f594d81f3f22f2aaba79a3d420a05af

use 5.006;
use warnings;
use Paws;
use Try::Tiny;
use Moo::Role;
use Data::Dumper;
use Carp;

=head1 NAME
	~
=head1 VERSION & HISTORY
	<feature>.<patch>
	0.01 - <date>
		<actions>
	0.00 - <date unless same as above>
		<actions>
=cut

=head1 SYNOPSIS
	TODO
=head2 TODO
	Generall planned work
=head1 EXPORT
=head1 ACCESSORS
=cut

ACCESSORS: {

	has s3 => (
		is      => 'rw',
		lazy    => 1,
		builder => sub {
			my ( $self ) = @_;
			$self->paws->service( 'S3', region => $self->paws_default_region );
		}
	);
	has s3_buffer_size => (
		is      => 'rw',
		lazy    => 1,
		default => sub { return 1024 }
	);

}

=head1 SUBROUTINES/METHODS
=head2 SETUP
=head3 new
=cut

=head3 paws_from_role_arn
	generate a new paws object derived from a role and ARN
=cut

sub s3_upload {

	my ( $self, $p, $x ) = @_;
	$x ||= {};
	$self->demand_params( $p, [qw/ source bucket/] );

	# 	$self->filechecks($p->{source});

	open( my $fh, '<:raw', $p->{source} ) || Carp::confess( "Problem opening $p->{source} : $!" );
	my $filecontent;
	while ( read( $fh, my $buffer, 4096 ) ) {
		$filecontent .= $buffer;
	}
	close( $fh );

	use Try::Tiny;
	my $res;
	try {

		# TODO 1. mime wizardry 2. multipart for large files
		$res = $self->s3->PutObject(
			Bucket => $p->{bucket},
			Key    => $p->{source} || $p->{target},
			Body   => $filecontent,

		);

		for my $method (
			qw/
			ETag
			Expiration
			RequestCharged
			SSECustomerAlgorithm
			SSECustomerKeyMD5
			SSEKMSEncryptionContext
			SSEKMSKeyId
			ServerSideEncryption
			VersionId
			/
		  )
		{
			print "$/ res->$method : " . $res->$method;

		}
	} catch {

		Carp::confess( "Unhandled failure :" . $_ );

	};

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
	Copyright 2019 mmacnair.
=head1 LICENSE
	TODO
=cut

1;
