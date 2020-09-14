#!/usr/bin/perl
use strict;
use warnings;
use Toolbox::CombinedCLI;

package TestObj;
use Moo;
with qw/
  Moo::GenericRole::AWS::Paws
  Moo::GenericRole::AWS::Paws::S3
  /;

1;

package main;
main();

sub main {

    my $obj = TestObj->new();
    my $c   = Toolbox::CombinedCLI::get_config(
        [
            qw/
              accesskey
              secretkey
              source

              bucket
              paws_default_region
              /
        ]
    );
  SETUP: {
        my $paws = $obj->paws_from_href(
            {
                AWSAccessKeyId => $c->{accesskey},
                AWSSecretKey   => $c->{secretkey},
            }
        );

        $obj->paws($paws);
        $obj->paws_default_region( $c->{paws_default_region} );
    }
    $obj->s3->ListObjects( Bucket => $c->{bucket} );

    # 	$obj->s3_upload( $c );

}
