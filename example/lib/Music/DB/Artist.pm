package Music::DB::Artist;
use base qw/DBIx::Class/;
__PACKAGE__->load_components(qw/PK::Auto Core/);
__PACKAGE__->table('artist');

__PACKAGE__->add_columns(
	id => {
		data_type         => 'INT',
		is_nullable       => 0,
		is_auto_increment => 1,
	},
	name => {
		data_type   => 'TEXT',
		is_nullable => 0,
	},
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->has_many(
	'albums' => 'Music::DB::Album',
	{ 'self.id' => 'foreign.album_id' }
);

__PACKAGE__->add_unique_constraint( [ 'name' ] );

1;
