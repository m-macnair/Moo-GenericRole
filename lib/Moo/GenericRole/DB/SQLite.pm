#ABSTRACT: overwrites/extensions to DB for SQLite
package Moo::GenericRole::DB::SQLite;
our $VERSION = 'v1.0.3';
##~ DIGEST : c3f135c38e936fc680f62d56c2a856ab
use Moo::Role;
use Carp qw/confess/;

=head3 get_dbh

=cut

sub get_dbh {

	my ( $self, $def, $opt ) = @_;
	$opt ||= {};
	$self->demand_params( $def, [qw/ database /] );
	confess( "SQLite Database file [$def->{database}] does not exist" ) unless -e $def->{database};
	confess( "SQLite Database file [$def->{database}] is unreadable" )  unless -r $def->{database};
	confess( "SQLite Database file [$def->{database}] is unwritable" )  unless -w $def->{database};
	$opt->{AutoCommit}                 ||= 0;
	$opt->{RaiseError}                 ||= 1;
	$opt->{sqlite_see_if_its_a_number} ||= 1;
	return $self->dbh_from_def( $def, $opt );

}
1;
