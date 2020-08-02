use strict;

package Moo::GenericRole::Common;

our $VERSION = 'v1.0.1';
##~ DIGEST : 4357d618aed86b5be5ebe60c7e3a22d7

use Moo::Role;
use 5.006;
use warnings;

=head1 NAME
	~
=head1 VERSION & HISTORY
	<breaking revision>.<feature>.<patch>
	1.0.0 - 2020-07-26
		The Mk1
=cut

=head1 SYNOPSIS
	Includer of everything in Common/ that I use, or wish I had used, in every project
=cut

with qw/
  Moo::GenericRole::Common::Debug
  Moo::GenericRole::Common::Core
  /;

=head1 AUTHOR
	mmacnair, C<< <mmacnair at cpan.org> >>
=head1 BUGS
	TODO Bugs
=head1 SUPPORT
	TODO Support
=head1 ACKNOWLEDGEMENTS
	TODO
=head1 COPYRIGHT
 	Copyright 2020 mmacnair.
=head1 LICENSE
	TODO
=cut

1;
