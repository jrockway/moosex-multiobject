package MooseX::MultiObject::Role;
# ABSTRACT: role that a MultiObject does
use Moose::Role;
use true;
use namespace::autoclean;

requires 'add_managed_object';
requires 'get_managed_objects';
