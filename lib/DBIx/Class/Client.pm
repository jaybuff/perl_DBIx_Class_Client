package DBIx::Class::Client;

use strict;
use warnings;

use Getopt::Long;
use Data::Dumper;
use Log::Log4perl qw(:easy);

use version; our $VERSION = qv("0.0.5");

sub new {
	my $proto  = shift;
	my $schema = shift;


	my $class = ref($proto) || $proto;
	return bless { db => $schema, }, $class;
}

sub run {
	my $self = shift;

	my $verb        = shift @ARGV || LOGDIE "missing verb";
	my $schema_name = shift @ARGV || LOGDIE "missing schema name";

	my $schema = eval { $self->get_db()->resultset($schema_name) };
	if ($@) {
		LOGDIE "Don't know anything about $schema_name";
	}

	if ( !$self->can($verb) ) {
		LOGDIE "Don't know how to $verb";
	}

	my $rs = $schema->result_source();

	my @get_opt_values;
	foreach my $column ( $rs->columns() ) {
		my $value       = $column;
		my $column_info = $rs->column_info($column);
		my $type        = $column_info->{data_type} || '';

		if ( $type eq "VARCHAR" || $type eq "TEXT" ) {
			$value .= '=s';
		}
		elsif ( $type eq "INT" ) {
			$value .= '=i';
		}
		else {
			LOGDIE "$value is of type $type.  Don't know how to handle that.";
		}

		push @get_opt_values, $value;
	}

	# get all the foreign keys that are unique and allow them to accessed like this:
	# --<foreign_table>_<foreign_column>
	#
	# since theses are unique in the foreign table, use it to get the foreign key
	# in this table
	my %fk_options;
	foreach my $relname ( $rs->relationships() ) {
		my $related_source = $rs->related_source($relname);

		foreach my $constraint_name ( $related_source->unique_constraint_names() ) {
			my @columns = $related_source->unique_constraint_columns($constraint_name);
			if ( @columns > 1 ) {

				# we can't handle multicolumn constraints
				next;
			}
			my $column = shift @columns;

			my $column_info = $related_source->column_info($column);
			my $type = $column_info->{data_type} || '';

			my $option_name = "${relname}_$column";

			# skip it if it exists in the parent table
			next if ( $rs->has_column($option_name) );

			$fk_options{$option_name} = {
				related_source         => $related_source,
				column                 => $column,
				relationship_condition => $rs->relationship_info($relname)->{cond},
			};

			my $option = $option_name;
			if ( $type eq "VARCHAR" || $type eq "TEXT" ) {
				$option .= '=s';
			}
			elsif ( $type eq "INT" ) {
				$option .= '=i';
			}
			else {
				LOGDIE "$option is of type $type.  Don't know how to handle that.";
			}

			push @get_opt_values, $option;
		}
	}

	my %opt;

	GetOptions( \%opt, @get_opt_values, ) or LOGDIE "Failed to get options";

	# this isn't quite right, my loop is in the wrong place.
	# there might be a bug when there are multiple fk columns because of this.
	foreach my $option ( keys %fk_options ) {
		my $opt_value = delete $opt{$option};
		if ( !$opt_value ) {
			next;
		}

		my $related_source = $fk_options{$option}->{related_source};
		my $cond           = $fk_options{$option}->{relationship_condition};
		my $column         = $fk_options{$option}->{column};
		my $obj            = $related_source->resultset()->find( { $column => $opt_value, } );

		if ( !$obj ) {
			LOGDIE "couldn't find column where $column => $opt_value in related source\n";
		}

		foreach my $foreign_column ( keys %{$cond} ) {
			my $self_column = $cond->{$foreign_column};

			# change self.id -> id
			# and foreign.load_balancer_id -> load_balancer_id
			$self_column    =~ s/.*?\.//;
			$foreign_column =~ s/.*?\.//;

			$opt{$self_column} = $obj->get_column($foreign_column);
		}
	}

	$self->$verb( $schema, \%opt );

    return;
}

sub dump_object {
	my $self = shift;
	my $obj  = shift;

	my $dump;
	foreach my $column ( $obj->columns() ) {
		$dump->{$column} = $obj->get_column($column) || '';
	}

	my $package = ref $obj;
	$package =~ s/(.*::)//;
	local $Data::Dumper::Varname = $package . "_";

	return Dumper $dump;

}

sub create { 
	my $self   = shift;
	my $schema = shift;
	my $values = shift;

	my $obj = $schema->create($values);

	INFO "created " . $self->dump_object($obj);

	return $obj;
}

# this is okay for perl critic because its a method, not a function
sub delete { ## no critic (Subroutines::ProhibitBuiltinHomonyms)
	my $self   = shift;
	my $schema = shift;
	my $values = shift;

	my $rs = $schema->search($values);

    if ( !$rs ) { 
        WARN "no records found to delete";
        return;
    } 

	INFO "Deleting these " . $rs->count() . " records...\n";
    while ( my $obj = $rs->next ) {
        INFO $self->dump_object($obj);
    }

	if ( !$rs->delete() ) {
		ERROR "Delete failed!";
		return;
	}

	return 1;
}

sub view {
	my $self   = shift;
	my $schema = shift;
	my $values = shift;

	my $rs = $schema->search($values);

    if ( !$rs ) {
        die "no records found.";
    }

	print "Found " . $rs->count() . " entries matching your args:\n";
    while ( my $obj = $rs->next ) {
        print $self->dump_object($obj);
    }

    return;

}

sub get_db {
	my $self = shift;

	if ( !$self->{db} ) {
		LOGDIE "Database was never initialized!";
	}

	return $self->{db};
}

1;

__END__

=head1 NAME

DBIx::Class::Client - create a simple command line client to insert, view and delete data into your database

=head1 DESCRIPTION

DBIx::Class::Client will allow you to easily create a command line interface to modify you're database.  It 
basically acts as glue between your DBIx::Class schema and Getopt::Long.

=head1 SYNOPSIS

Check out the examples/ directory included in the distribution.  Go into that directory and run these commands:

    # first deploy the SQLite database for testing:
    $ perl -MMusic::DB -le "Music::DB->connect( 'dbi:SQLite:dbname=/tmp/musicdb', '', '' )->deploy();"

    # take a look at what kind of database that created:
    $ sqlite3 /tmp/musicdb
    SQLite version 3.3.8
    Enter ".help" for instructions
        
    sqlite> .tables
    album   artist  track 

    sqlite> .schema artist
    CREATE TABLE artist (
      id INTEGER PRIMARY KEY NOT NULL,
      name TEXT NOT NULL
    );
    CREATE UNIQUE INDEX artist_name_artist on artist (name);

    sqlite> .schema album
    CREATE TABLE album (
      id INTEGER PRIMARY KEY NOT NULL,
      artist_id INT NOT NULL,
      title TEXT NOT NULL
    );
    CREATE UNIQUE INDEX album_title_album on album (title);

    sqlite> .schema track
    CREATE TABLE track (
      id INTEGER PRIMARY KEY NOT NULL,
      album_id INT NOT NULL,
      title TEXT NOT NULL
    );

    sqlite> .exit

    # add a couple of entries to the artist database table
    $ ./music.pl create Artist --name "The Beatles"
    $ ./music.pl create Artist --name Radiohead

    # add entries to the album table, using the entries we just made as a foreign key
    # any unique key from the foreign table will work
    $ ./music.pl create Album --artist_name "The Beatles" --title "White Album"
    $ ./music.pl create Album --artist_name Radiohead --title "In Rainbows"
    $ ./music.pl create Album --artist_name Radiohead --title "OK Computer"

    # add some tracks:
    $ ./music.pl create Track --album_title "White Album" --title Blackbird
    $ ./music.pl create Track --album_title "White Album" --title "Helter Skelter" 
    $ ./music.pl create Track --album_title "White Album" --title Revolution
    $ ./music.pl create Track --album_title "OK Computer" --title AirBag 
    $ ./music.pl create Track --album_title "OK Computer" --title "Paranoid Andriod"
    $ ./music.pl create Track --album_title "OK Computer" --title "Fake Plastic Tree"
    $ ./music.pl create Track --album_title "In Rainbows" --title "15 Steps"
    $ ./music.pl create Track --album_title "In Rainbows" --title "All I Need"

    # now view all the Albums 
    $ ./music.pl view Album
    Found 3 entries matching your args:
    $Album_1 = {
                 'artist_id' => 1,
                 'title' => 'White Album',
                 'id' => 1
               };
    $Album_1 = {
                 'artist_id' => 2,
                 'title' => 'In Rainbows',
                 'id' => 2
               };
    $Album_1 = {
                 'artist_id' => 2,
                 'title' => 'OK Computer',
                 'id' => 3
               };

    # view all the tracks on OK Computer
    $ ./music.pl view Track --album_title "OK Computer"
    Found 3 entries matching your args:
    $Track_1 = {
                 'album_id' => 3,
                 'title' => 'AirBag',
                 'id' => 4
               };
    $Track_1 = {
                 'album_id' => 3,
                 'title' => 'Paranoid Andriod',
                 'id' => 5
               };
    $Track_1 = {
                 'album_id' => 3,
                 'title' => 'Fake Plastic Tree',
                 'id' => 6
               };

    # Whops! Fake Plastic Tree wasn't on the OK Computer album, it was on The Bends.  Delete it.
    $ ./music.pl delete Track --title "Fake Plastic Tree"

    # see that it's been deleted:
    $ ./music.pl view Track --album_title "OK Computer"
    Found 2 entries matching your args:
    $Track_1 = {
                 'album_id' => 3,
                 'title' => 'AirBag',
                 'id' => 4
               };
    $Track_1 = {
                 'album_id' => 3,
                 'title' => 'Paranoid Andriod',
                 'id' => 5
           };

    $ 


=head1 METHODS

=over 8

=item C<< my $client = DBIx::Class::Client->new( $schema ) >>

=item C<< $client->run() >>

=item C<< $client->create() >>

=item C<< $client->delete() >>

=item C<< $client->view() >>

=item C<< $client->dump_object() >>

=item C<< $client->get_db() >>

=back

=head1 BUGS 

Lots.  This is alpha software.  It works for me and meets my immediate needs.  Please submit test cases and patches!

=head1 AUTHOR 

Jay Buffington <dbixclassclient@jaybuff.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2008, Yahoo! Inc.  All rights reserved.
Copyrights licensed under the New BSD License. 
See the accompanying LICENSE file for terms.

=cut
