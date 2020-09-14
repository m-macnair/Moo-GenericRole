package Moo::GenericRole::DB::MariaMysql;
our $VERSION = 'v1.0.4';

##~ DIGEST : aca01ad1a03c76abdbf6494c95fcc403
#ABSTRACT: overwrites/extensions to DB for maria/mysql
use Moo::Role;

around "last_insert_id" => sub {
    my $orig = shift;
    my $self = shift;
    return $self->dbh->{mysql_insertid};
};

1;
