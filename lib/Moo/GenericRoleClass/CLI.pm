#ABSTRACT: Do the thing I do for command line scripts
package Moo::GenericRoleClass::CLI;
our $VERSION = 'v1.0.14';
##~ DIGEST : bd1cb60f4881d0d4ca39f20e2a5732d9
use Moo;
with qw/
  Moo::GenericRole::Common
  Moo::GenericRole::CombinedCLI
  Moo::GenericRole::ConfigAny
  Moo::GenericRole::FileSystem
  /;

1;
