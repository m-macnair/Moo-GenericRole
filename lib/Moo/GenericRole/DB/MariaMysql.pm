package Moo::GenericRole::DB::MariaMysql;
our $VERSION = 'v1.0.3';

##~ DIGEST : c13ce2d8885257efa5bdac01086528e3
#ABSTRACT: overwrites/extensions to DB for maria/mysql
use Moo::Role;

around "last_insert_id" => sub {
	my $orig = shift;
	my $self = shift;
	return $self->dbh->{mysql_insertid};
};

1;
