package Music::DB::Track;
use base qw/DBIx::Class/;
__PACKAGE__->load_components(qw/PK::Auto Core/);
__PACKAGE__->table('track');

__PACKAGE__->add_columns(
	id => {
		data_type         => 'INT',
		is_nullable       => 0,
		is_auto_increment => 1,
	},
	album_id => {
		data_type   => 'INT',
		is_nullable => 0,
	},
	title => {
		data_type   => 'TEXT',
		is_nullable => 0,
	}
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to(
	'album' => 'Music::DB::Album',
	{ 'foreign.id' => 'self.album_id' }
);

1;
