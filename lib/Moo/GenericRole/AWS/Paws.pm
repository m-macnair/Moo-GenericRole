use strict; # applies to all packages defined in the file

package Moo::GenericRole::AWS::Paws;
our $VERSION = 'v1.0.7';
##~ DIGEST : f1af42b5608100ba790762e904ab0734
use 5.006;
use warnings;
use Paws;
use Try::Tiny;
use Moo::Role;
use Data::Dumper;
use Carp;
use Paws::Credential::Explicit;
with qw/
  Moo::GenericRole::UUID
  Moo::GenericRole::Common::Core
  Moo::GenericRole::Common::Debug
  /;

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
	has paws => (
		is      => 'rw',
		lazy    => 1,
		default => sub {
			Carp::confess( "paws accessor not initialised and no default overwrite provided" );
		}
	);
	has paws_default_region => (
		is      => 'rw',
		lazy    => 1,
		default => sub {
			Carp::confess( "paws_default_region accessor not initialised and no default overwrite provided" );
		}
	);
}

=head1 SUBROUTINES/METHODS
=head2 SETUP
=head3 new
=cut

=head3 paws_from_role_arn
	generate a new paws object derived from a role and ARN
=cut

sub paws_from_role_arn {

	my ( $self, $p ) = @_;
	$self->demand_params( $p, [qw/arn/] );
	my $identifier  = $p->{identifier} || "identifier_" . time;
	my $sessionname = $identifier . '_' . $self->getuuid();
	$self->debug_msg( "awsgetrolecred about to try and create sessionname : $sessionname" );
	my $stsobj = $self->any_paws()->service( 'STS' );
	try {
		my $res = $stsobj->AssumeRole(
			RoleArn         => $p->{arn},
			RoleSessionName => $sessionname
		);
		if ( $res->{Credentials} ) {
			my $token;
			my $cred = {%{$res->{Credentials}}};
			require Paws::Credential::Explicit;
			$self->demandparams( $cred, [qw/AccessKeyId SecretAccessKey SessionToken /], {croak => 1} );
			return Paws->new(
				config => {
					credentials => Paws::Credential::Explicit->new(
						access_key    => $cred->{AccessKeyId},
						secret_key    => $cred->{SecretAccessKey},
						session_token => $cred->{SessionToken},
					)
				}
			);
		} else {
			Carp::croak( "No role credentials provided in response - " . $self->ddumper( $res ) );
		}
	} catch {
		Carp::confess( "Failure attempting to assume a role : $_" );
	}

}

sub paws_from_href {

	my ( $self, $p, $x ) = @_;
	$x ||= {};
	$self->demand_params(
		$p,
		[
			qw/
			  AWSAccessKeyId
			  AWSSecretKey
			  /
		]
	);
	my $conf = {
		access_key => $p->{AWSAccessKeyId},
		secret_key => $p->{AWSSecretKey},
		%{$x}
	};
	my $cred_obj = Paws::Credential::Explicit->new( $conf );
	my $paws     = Paws->new( config => {credentials => $cred_obj} );
	return $paws;

}

=head3 any_paws
	if $self->paws() is set, return that; otherwise create a new one and *do not* assign to the accessor
=cut

sub any_paws {

	my ( $self, $p ) = @_;
	if ( ref( $self->paws() ) eq 'Paws' ) {
		return $self->paws();
	} else {
		return Paws->new();
	}

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
