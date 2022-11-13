#ABSTRACT: provide $self->xml_load_file and $self->load_string
package Moo::GenericRole::XMLRead;
our $VERSION = 'v0.0.0';
##~ DIGEST : 27bc0537638ecaa85f2cfc5c14e57a20
use Moo::Role;
with qw/Moo::GenericRole/;
use XML::LibXML::Reader;
use Try::Tiny;
ACCESSORS: {
	has xml_reader => (
		is      => 'rw',
		lazy    => 1,
		default => sub {
			my ( $self ) = @_;
			$self->_get_json();
		}
	);
}


sub sub_on_xml_file {
    my ($self,$sub,$path,$p) =@_;
    unless(ref($sub) eq 'CODE'){
        die "First argument to sub_on_xml_file is not a code ref";
    }
    unless(-e $path){
        die "Second argument [$path] to sub_on_xml_file is not a valid path";
    }
    $p ||= {};
    my $reader = XML::LibXML::Reader->new(location => "$path")
        or die "cannot read [$path] : $!\n";
    while ($reader->read()){
        last unless &$sub($reader);
    }
}





1;
