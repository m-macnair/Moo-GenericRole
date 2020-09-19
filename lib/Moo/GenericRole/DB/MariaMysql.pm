package Moo::GenericRole::DB::MariaMysql;
our $VERSION = 'v1.0.6';
##~ DIGEST : f9fd6c9d35cbd917e73e0015eb652fe5
#ABSTRACT: overwrites/extensions to DB for maria/mysql
use Moo::Role;
around "last_insert_id" => sub {
	my $orig = shift;
	my $self = shift;
	return $self->dbh->{mysql_insertid};
};
1;
