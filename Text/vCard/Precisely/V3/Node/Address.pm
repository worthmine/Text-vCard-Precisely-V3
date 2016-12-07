package Text::vCard::Precisely::V3::Node::Address;
use Carp;
use Encode;

use Moose;
use Moose::Util::TypeConstraints;

extends 'Text::vCard::Precisely::V3::Node';

has name => (is => 'ro', default => 'ADR', isa => 'Str' );
has value => (is => 'ro', default => '', isa => 'Str' );

has [qw( pobox extended street city region post_code country )]
    => ( is => 'rw', isa => 'Str' );

override 'as_string' => sub {
    my ($self) = @_;
    my @lines;
    push @lines, $self->name || croak "Empty name";
    push @lines, 'TYPE="' . join( ',', @{ $self->types } ). '"' if @{ $self->types || [] } > 0;
    push @lines, 'ALTID=' . $self->altID if $self->altID;
    push @lines, 'PID=' . join ',', @{ $self->pid } if $self->pid;
    push @lines, 'LANGUAGE=' . $self->language if $self->language;

    ( my $pobox     = $self->pobox    ) =~ s/([,;\\])/\\$1/sg;
    ( my $extended  = $self->extended ) =~ s/([,;\\])/\\$1/sg;
    ( my $street    = $self->street   ) =~ s/([,;\\])/\\$1/sg;
    ( my $city      = $self->city     ) =~ s/([,;\\])/\\$1/sg;
    ( my $region    = $self->region   ) =~ s/([,;\\])/\\$1/sg;
    ( my $post_code = $self->post_code) =~ s/([,;\\])/\\$1/sg;
    ( my $country   = $self->country  ) =~ s/([,;\\])/\\$1/sg;

    my $line = join(';', @lines ) . ':' . join ';',
    $pobox      || '',
    $extended   || '',
    $street     || '',
    $city       || '',
    $region     || '',
    $post_code  || '',
    $country    || '';
};

__PACKAGE__->meta->make_immutable;
no Moose;
    
1;