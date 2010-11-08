package MooseX::MultiObject::Meta::Class;
# ABSTRACT: metarole for MultiObject metaclass
use Moose::Role;
use true;
use namespace::autoclean;

has 'set_attribute_name' => (
    reader    => 'get_set_attribute_name',
    writer    => 'set_set_attribute_name',
    predicate => 'has_set_attribute_name',
    isa       => 'Str',
);
