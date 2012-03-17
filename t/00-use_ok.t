#!/usr/local/bin/perl 

use Test::More tests => 1;

BEGIN {
	use FindBin;
	use lib "$FindBin::Bin/../lib";
}

use_ok( 'DBIx::Class::Client' );
