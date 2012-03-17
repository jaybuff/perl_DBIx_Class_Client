package Music::DB;
use DBIx::Class::Schema;
use base qw/DBIx::Class::Schema/;
__PACKAGE__->load_classes(qw/Artist Album Track/);

1;
