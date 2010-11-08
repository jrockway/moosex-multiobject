package MooseX::MultiObject;
# ABSTRACT: make a set of objects behave like a single object
use Moose ();
use Moose::Exporter;
use true;
use MooseX::Types::Set::Object;
use MooseX::APIRole::Internals qw(create_role_for);
use Moose::Util qw(does_role with_traits);
use Moose::Meta::TypeConstraint::Role;
use MooseX::MultiObject::Role;
use MooseX::MultiObject::Meta::Method::MultiDelegation;
use Set::Object qw(set);
use Carp qw(confess);

Moose::Exporter->setup_import_methods(
    with_meta        => ['setup_multiobject'],
    class_metaroles  => { class => ['MooseX::MultiObject::Meta::Class'] },
);

# eventually there will be a metaprotocol for this.  for now... you
# will really like Set::Object, i know it.
sub setup_multiobject {
    my ($meta, %args) = @_;
    my $attribute = $args{attribute} || {
        init_arg => 'objects',
        coerce   => 1,
        is       => 'ro',
    };
    $attribute->{name}    ||= 'set';
    $attribute->{isa}     ||= 'Set::Object';
    $attribute->{default} ||= sub { set };
    $attribute->{coerce}  //= 1;
    $attribute->{handles} ||= {};

    confess 'you already have a set attribute name.  bailing out.'
        if $meta->has_set_attribute_name;

    my $name = delete $attribute->{name};
    $meta->add_attribute( $name => $attribute );
    $meta->set_set_attribute_name( $name ); # set is a verb and a noun!

    confess 'you must not specify both a class and a role'
        if exists $args{class} && exists $args{role};

    my $role;
    if(my $class_name = $args{class}){
        my $class = blessed $class_name ? $class_name : $class_name->meta;
        $role = does_role( $class, 'MooseX::APIRole::Meta' ) ?
            $class->as_api_role : create_role_for($class);
    }
    elsif(my $role_name = $args{role}){
        $role = blessed $role_name ? $role_name : $role_name->meta;
        confess "provided role '$role' is not a Moose::Meta::Role!"
            unless $role->isa('Moose::Meta::Role');

    }
    else {
        confess 'you must specify either a class or a role'; # OR DIE
    }

    my $tc = Moose::Meta::TypeConstraint::Role->new( role => $role );
    # $meta->set_set_type_constraint($tc);

    # add adder method -- named verbosely for maximum
    # not-conflicting-with-stuff
    $meta->add_method( add_managed_object => sub {
        my ($self, $thing) = @_;
        $tc->assert_valid($thing);
        $self->$name->insert($thing);
        return $thing;
    });

    # add getter
    $meta->add_method( get_managed_objects => sub {
        my ($self) = @_;
        return $self->$name->members;
    });

    # now invite the superdelegates
    my @methods = grep { $_ ne 'meta' } (
        $role->get_method_list,
        (map { $_->name } $role->get_required_method_list),
    );

    for my $method (@methods) {
        my $metamethod = MooseX::MultiObject::Meta::Method::MultiDelegation->new(
            name          => $method,
            package_name  => $meta->name,
            object_getter => 'get_managed_objects',
            delegate_to   => $method,
        );
        $meta->add_method($method => $metamethod);
    }

    MooseX::MultiObject::Role->meta->apply($meta);
    $role->apply($meta);

    return $meta;
}

__END__

=head1 SYNOPSIS
