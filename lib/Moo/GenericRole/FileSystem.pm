package Moo::GenericRole::FileSystem;

# ABSTRACT: filesystem-y things + functional version too
use Moo::Role;
use Toolbox::FileSystem;
our $VERSION = 'v1.0.3';

##~ DIGEST : 3b58d5a4f861fc6f9d3f8a57a47646c1

use POSIX;
use Data::UUID;
ACCESSORS: {
    has tmpdir => (
        is      => 'rw',
        lazy    => 1,
        default => sub {
            my ($self) = @_;
            $self->buildtmpdir();
        }
    );
    has tmproot => (
        is      => 'rw',
        lazy    => 1,
        default => sub {
            return "$ENV{HOME}/tmp/";
        }
    );

}

sub buildtmpdir {
    my ( $self, $root ) = @_;
    my $path = $self->buildtmpdirpath($root);
    $self->mkpath($path);
    return $path;
}

sub buildtmpdirpath {
    my ( $self, $root ) = @_;
    $root ||= $self->tmproot();
    return $self->buildtimepath($root);

}

sub buildtimepath {
    my ( $self, $root ) = @_;
    $self->checkdir($root);

    my $ug      = Data::UUID->new;
    my $uuid    = lc( $ug->create_str() );
    my $tmppath = POSIX::strftime( "/%Y-%m-%d/%H/%M:%S/", gmtime() );
    return $self->abspath("$root/$tmppath/$uuid");
}

# Direct 'use the functional version' method calls, because why not
FUNCTIONALPORTS: {
    sub checkpath    { shift; return Toolbox::FileSystem::checkpath(@_); }
    sub checkfile    { shift; return Toolbox::FileSystem::checkfile(@_); }
    sub checkdir     { shift; return Toolbox::FileSystem::checkdir(@_); }
    sub subonfiles   { shift; return Toolbox::FileSystem::subonfiles(@_); }
    sub sub_on_files { shift; return Toolbox::FileSystem::sub_on_files(@_); }
    sub filebasename { shift; return Toolbox::FileSystem::filebasename(@_); }
    sub mvf          { shift; return Toolbox::FileSystem::mvf(@_); }
    sub safemvf      { shift; return Toolbox::FileSystem::safemvf(@_); }
    sub cpf          { shift; return Toolbox::FileSystem::cpf(@_); }
    sub abspath      { shift; return Toolbox::FileSystem::abspath(@_); }
    sub mkpath       { shift; return Toolbox::FileSystem::mkpath(@_); }

    sub safeduplicatepath {
        shift;
        return Toolbox::FileSystem::safeduplicatepath(@_);
    }

}

1;
