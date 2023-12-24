use strict;
use warnings;

use ExtUtils::MakeMaker;
WriteMakefile(
	NAME         => 'Moo::GenericRole',
	VERSION_FROM => 'lib/Moo/GenericRole.pm',
	LICENSE      => 'perl',
	PREREQ_PM    => {
		'SQL::Abstract' => '0',
	},

);
