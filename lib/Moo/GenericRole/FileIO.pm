package Moo::GenericRole::FileIO;
our $VERSION = 'v1.0.4';

##~ DIGEST : 0c4316bbc5b0701a3431b73665d4f7f7
# ABSTRACT: persistent file IO
use Toolbox::FileIO;
use Moo::Role;

ACCESSORS: {
    has filehandles => (
        is      => 'rw',
        lazy    => 1,
        default => sub {
            return {};
        }
    );

}

# Almost but not quite cargo cultin'
sub ofh {
    my ( $self, $path, $c ) = @_;
    $c ||= {};
    unless ( exists( $self->filehandles->{$path} ) ) {
        if ( $c->{fh} ) {
            $self->filehandles->{$path} = $c->{fh};
        }
        else {
            unless (
                open(
                    $self->filehandles->{$path},
                    $c->{openparams} || ">:encoding(UTF-8)",
                    $path
                )
              )
            {
                confess("Failed to open write file [$path] : $!");
            }
        }
    }
    return $self->filehandles->{$path};
}

sub closefhs {
    my ( $self, $paths ) = @_;

    #close all unless specific
    $paths ||= [ keys( %{ $self->filehandles } ) ];
    use Data::Dumper;

    for ( @{$paths} ) {
        close( $self->filehandles->{$_} )
          or confess("Failed to close file handle for [$_] : $!");
        undef( $self->filehandles->{$_} );
    }

}

1;
