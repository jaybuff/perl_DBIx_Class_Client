#!/usr/local/bin/perl

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME          => 'DBIx::Class::Client',
	AUTHOR        => 'Jay Buffington <dbixclassclient@jaybuff.com>',
	VERSION_FROM  => 'lib/DBIx/Class/Client.pm',
	ABSTRACT_FROM => 'lib/DBIx/Class/Client.pm',
	PL_FILES      => {},
	PREREQ_PM     => {
		'Log::Log4perl'        => 0,
		'version'              => 0,
		# the following modules are only needed for running tests
		'Test::Data'           => 0,
		'Test::Exception'      => 0,
		'Test::More'           => 0,
		'Test::Pod'            => 0,
		'Test::Pod::Coverage'  => 0,
	},
	dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean => { FILES    => 'DBIx-Class-Client-*' },
);
