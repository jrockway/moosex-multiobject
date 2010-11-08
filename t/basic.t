use strict;
use warnings;
use Test::More;
use Scalar::Util qw(refaddr);
use Moose::Util qw(does_role);

{ package Role;
  use Moose::Role;
  requires 'foo';
  requires 'bar';
}

{ package Object;
  use Moose;
  has [qw/foo bar baz/] => ( is => 'rw' );
  with 'Role';
  Object->meta->make_immutable;
}

{ package Set;
  use Moose;
  use MooseX::MultiObject;

  setup_multiobject (
      role => 'Role',
  );
}

for(1..2){
    my $a = Object->new;
    my $b = Object->new( foo => 42, bar => 123 );

    my $set = Set->new( objects => [$b] );
    is_deeply [$set->foo], [42], 'set->foo works';
    is_deeply [$set->bar], [123], 'set->bar works';
    ok !$set->can('baz'), 'set cannot baz';
    $set->add_managed_object($a);

    is_deeply [sort map { refaddr $_ } $set->get_managed_objects],
              [sort map { refaddr $_ } $a, $b],
        'got objects';

    { no warnings 'uninitialized';
      is_deeply [sort $set->foo], [sort 42, undef], 'set->foo works';
      is_deeply [sort $set->bar], [sort 123, undef], 'set->bar works';
    }
    $set->foo('yay');
    is_deeply [$set->foo], ['yay', 'yay'], 'setting works';
    is $a->foo, 'yay';
    is $b->foo, 'yay';

    diag "retrying tests after make_immutable" if $_ == 1;
    Set->meta->make_immutable;
}

ok does_role('Set', 'MooseX::MultiObject::Role'), 'does multiobject role';
ok does_role('Set', 'Role'), 'does { role => ... } role';

done_testing;
