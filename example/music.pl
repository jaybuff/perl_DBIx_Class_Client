#!/usr/local/bin/perl

use strict;
use warnings;

use lib './lib', '../lib';

use Music::DB;
use DBIx::Class::Client;

my $music = Music::DB->connect( "dbi:SQLite:dbname=/tmp/musicdb", '', '' );
my $client = DBIx::Class::Client->new($music);
$client->run();
