#ABSTRACT: Do the thing I do for command line scripts
package Moo::GenericRoleClass::CLI;
our $VERSION = 'v1.0.13';
##~ DIGEST : 0ac9f10ebd9c9b9b69f05a950a47d493
use Moo;
with qw/
  Moo::GenericRole::Common
  Moo::GenericRole::CombinedCLI
  Moo::GenericRole::Config::Any
  Moo::GenericRole::FileSystem
  /;

1;
