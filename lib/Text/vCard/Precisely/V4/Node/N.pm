package Text::vCard::Precisely::V4::Node::N;

use Carp;
use Moose;
#use Moose::Util::TypeConstraints;
my @order = qw( family given additional prefixes suffixes );

extends 'Text::vCard::Precisely::V3::Node::N';

has sort_as => ( is => 'rw', isa => 'Str' );

override 'as_string' => sub {
    my ($self) = @_;
    my @lines;
    push @lines, $self->name || croak "Empty name";
    push @lines, 'ALTID=' . $self->altID if $self->altID;
    push @lines, 'LANGUAGE=' . $self->language if $self->language;
    push @lines, 'CHARSET=' . $self->charset if $self->charset;
    push @lines, 'SORT-AS=' . $self->sort_as if $self->sort_as;

    my @values = ();
    my $num = 0;
    map{ push @values, $self->_escape( $self->$_ || $self->value->[$num++] ) } @order;
    my $string = join(';', @lines ) . ':' . join ';', @values;
    return $self->fold( $string, -force => 1 );
};

__PACKAGE__->meta->make_immutable;
no Moose;

1;
