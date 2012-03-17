#!/usr/local/bin/perl

use strict;
use warnings;

BEGIN {
	use FindBin;
	use lib "$FindBin::Bin/../lib";
	use lib "$FindBin::Bin/../example/lib";
}

use Test::More tests => 7;
use Test::Exception;
use Music::DB;
use DBIx::Class::Client;
use File::Temp;

# create the SQLite database and deploy the schema
my ( $fh, $filename ) = File::Temp::tempfile();
my $music = Music::DB->connect( "dbi:SQLite:dbname=$filename", '', '' );
$music->deploy();

# now try adding/deleting some entries
my $client = DBIx::Class::Client->new($music);

lives_ok( sub {  
    @ARGV = qw(create Artist --name Beatles);
    $client->run();
}, "didn't die while inserting the beatles into artists");


# this is a new database, so we're gaurenteed that the id of the row we just inserted was 1
is( $music->resultset('Artist')->find( 1 )->name(), "Beatles", "beatles artist was actually inserted" );

lives_ok( sub {  
    @ARGV = qw(view Artist --name Beatles);
    $client->run();
}, "didn't die while viewing the beatles artist");

# add an album that is by the beatles
lives_ok( sub {  
    @ARGV = (qw(create Album --artist_name Beatles --title),  "Yellow Submarine");
    $client->run();
}, "didn't die while adding yellow submarine");

is( $music->resultset('Album')->find( 1 )->title(), "Yellow Submarine", "beatles album was actually inserted" );


lives_ok( sub {  
    @ARGV = qw(delete Artist --name Beatles);
    $client->run();
}, "didn't die while inserting the beatles into artists");

is( $music->resultset('Artist')->search( { name => "Beatles" } )->count(), 0, "beatles artist was actually deleted" );
