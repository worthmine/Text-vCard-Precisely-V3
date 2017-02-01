package Text::vCard::Precisely::V3::Node;
$VERSION = 0.01;

use Carp;
use Encode;

use overload (
    q{""}	=> \&as_string,
);

use Moose;
use Moose::Util::TypeConstraints;

enum 'Name' => [qw( VERSION PRODID N FN
    KIND REV BDAY ANNIVERSARY GENDER
    ADR LABEL TEL EMAIL PHOTO LOGO URL UID
    TZ GEO NICKNAME IMPP LANG XML KEY NOTE
    ORG TITLE ROLE CATEGORIES
    SOURCE SOUND FBURL CALADRURI CALURI
    X-SOCIALPROFILE SORT_STRING
)];
has name => ( is => 'rw', required => 1, isa => 'Name' );

subtype 'VALUE'
    => as 'Str'
    => where { use utf8; decode_utf8($_) =~  m|^[\w\W\s]*$|s }   # it needs to be more strictly
    => message { "The VALUE you provided, $_, was not supported" };
has value => ( is => 'rw', required => 1, isa => 'VALUE' );

has pref => ( is => 'rw', isa => subtype 'Preffered'
    => as 'Int'
    => where { $_ > 0 and $_ <= 100 }
    => message { "The number you provided, $_, was not supported in 'Preffered'" }
);

subtype 'Type'
    => as 'Str'
    => where {
        m/^(:?work|home)$/is or #common
        m/^(:?contact|acquaintance|friend|met|co-worker|colleague|co-resident|neighbor|child|parent|sibling|spouse|kin|muse|crush|date|sweetheart|me|agent|emergency)$/is or    # it needs tests
        m|^(:?[a-zA-z0-9\-]+/X-[a-zA-z0-9\-]+)$|s; # does everything pass?
    }
    => message { "The text you provided, $_, was not supported in 'Type'" };
has types => ( is => 'rw', isa => 'ArrayRef[Type]', default => sub{ [] } );

subtype 'PIDNum'
    => as 'Num'
    => where { m/^\d(:?.\d)?$/s }
    => message { "The PID you provided, $_, was not supported" };
has pid => ( is => 'rw', isa => subtype 'PID' => as 'ArrayRef[PIDNum]' );

has altID => ( is => 'rw', isa => subtype 'ALTID'
    => as 'Int'
    => where { $_ > 0 and $_ <= 100 }
    => message { "The number you provided, $_, was not supported in 'ALTID'" }
);


has language => ( is => 'rw', isa => subtype 'Language'
    => as 'Str'
    => where { m|^[a-z]{2}(:?-[a-z]{2})?$|s }  # does it need something strictly?
    => message { "The Language you provided, $_, was not supported" }
);

has media_type => ( is => 'rw', isa => subtype 'MediaType'
    => as 'Str'
    => where { m{^(:?application|audio|example|image|message|model|multipart|text|video)/[\w+\-\.]+$}is }
    => message { "The MediaType you provided, $_, was not supported" }
);

has sort_as => ( is => 'rw', isa => subtype 'SortAs' # from vCard 4.0
    => as 'Str'
    => where { use utf8; decode_utf8($_) =~  m|^[\w\s\W]+$|s }   # does everything pass?
    => message { "The SortAs you provided, $_, was not supported" }
);

has charset => ( is => 'rw', isa => subtype 'Charset' # not recommend for vCard 4.0
    => as 'Str'
    => where { m|^[\w-]+$|s }    # does everything pass?
    => message { "The Charset you provided, $_, was not supported" }
);

__PACKAGE__->meta->make_immutable;
no Moose;

sub as_string {
    my ($self) = @_;
    my @lines;
    push @lines, uc( $self->name ) || croak "Empty name";
    push @lines, 'TYPE=' . join( ',', map { uc $_ } @{ $self->types } ) if @{ $self->types || [] } > 0;
    push @lines, 'PREF=' . $self->pref if $self->pref;
    push @lines, 'MEDIATYPE=' . $self->media_type if $self->media_type;
    push @lines, 'ALTID=' . $self->altID if $self->altID;
    push @lines, 'LANGUAGE=' . $self->language if $self->language;
    push @lines, 'PID=' . join ',', @{ $self->pid } if $self->pid;
    push @lines, 'CHARSET=' . $self->charset if $self->charset;
    push @lines, 'SORT-AS=' . $self->sort_as if $self->sort_as and $self->name eq 'ORG';

    return join(';', @lines ) . ':' . (
        ref $self->value eq 'Array'?
        map{ Text::vCard::Precisely::V3::_escape($_) } @{ $self->value }:
        Text::vCard::Precisely::V3::_escape( $self->value )
    );
}

1;
