package Music::DB::Album;
use base qw/DBIx::Class/;
__PACKAGE__->load_components(qw/PK::Auto Core/);
__PACKAGE__->table('album');

__PACKAGE__->add_columns(
	id => {
		data_type         => 'INT',
		is_nullable       => 0,
		is_auto_increment => 1,
	},
	artist_id => {
		data_type   => 'INT',
		is_nullable => 0,
	},
	title => {
		data_type   => 'TEXT',
		is_nullable => 0,
	},
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to(
	'artist' => 'Music::DB::Artist',
	{ 'foreign.id' => 'self.artist_id' }
);

__PACKAGE__->has_many(
	'tracks' => 'Music::DB::Track',
	{ 'foreign.album_id' => 'self.id' }
);

__PACKAGE__->add_unique_constraint( [ 'title' ] );

1;
