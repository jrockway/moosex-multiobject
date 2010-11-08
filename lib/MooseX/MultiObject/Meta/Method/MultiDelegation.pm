package MooseX::MultiObject::Meta::Method::MultiDelegation;
# ABSTRACT: method that delegates to a set of object
use strict;
use warnings;
use true;
use namespace::autoclean;
use Carp qw(confess);

use parent 'Moose::Meta::Method', 'Class::MOP::Method::Generated';

# i hate class mop

sub new {
    my $class   = shift;
    my %options = @_;

    confess 'You must supply an object_getter method name'
        unless exists $options{object_getter};

    confess 'You must supply a delegate_to method or coderef'
        unless exists $options{delegate_to};

    exists $options{curried_arguments}
        || ( $options{curried_arguments} = [] );

    ( $options{curried_arguments} &&
        ( 'ARRAY' eq ref $options{curried_arguments} ) )
        || confess 'You must supply a curried_arguments which is an ARRAY reference';

    my $self = $class->_new( \%options );

    $self->_initialize_body;

    return $self;
}

sub _new {
    my $class = shift;
    my $options = @_ == 1 ? $_[0] : {@_};

    return bless $options, $class;
}

sub object_getter { $_[0]->{object_getter} }
sub curried_arguments { $_[0]->{curried_arguments} }
sub delegate_to { $_[0]->{delegate_to} }

sub _initialize_body {
    my $meta = shift;

    my $object_getter = $meta->object_getter;
    my @extra_args    = @{$meta->curried_arguments};
    my $delegate_to   = $meta->delegate_to;

    $meta->{body} = sub {
        my $self = shift;
        unshift @_, @extra_args;
        my @objects = $self->$object_getter;
        return map { scalar $_->$delegate_to(@_) } @objects;
    };
}
