# ABSTRACT: turns baubles into trinkets
package Text::vCard::Precisely::V3;
$VERSION = 0.01;

use 5.10.1;
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Types::DateTime qw(TimeZone);

use Carp;
use Data::UUID;
use Encode;
use Text::LineFold;
use URI;

use Text::vCard::Precisely::V3::Node;
use Text::vCard::Precisely::V3::Node::N;
use Text::vCard::Precisely::V3::Node::Address;
use Text::vCard::Precisely::V3::Node::Phone;
use Text::vCard::Precisely::V3::Node::Email;
use Text::vCard::Precisely::V3::Node::Photo;
use Text::vCard::Precisely::V3::Node::URL;
use Text::vCard::Precisely::V3::Node::SocialProfile;

has encoding_in  => ( is => 'rw', isa => 'Str', default => 'UTF-8', );
has encoding_out => ( is => 'rw', isa => 'Str', default => 'UTF-8', );
has version => ( is => 'rw', isa => 'Str', default => '3.0' );

subtype 'N'
    => as 'Text::vCard::Precisely::V3::Node::N';
coerce 'N'
    => from 'HashRef[Maybe[Ref]|Maybe[Str]]'
    => via {
        my %param;
        while( my ($key, $value) = each %$_ ) {
            $param{$key} = $value if $value;
        }
        return Text::vCard::Precisely::V3::Node::N->new(\%param);
    };
coerce 'N'
    => from 'HashRef[Maybe[Str]]'
    => via { Text::vCard::Precisely::V3::Node::N->new({ value => $_ }) };
coerce 'N'
    => from 'ArrayRef[Maybe[Str]]'
    => via { Text::vCard::Precisely::V3::Node::N->new({ value => {
        family      => $_->[0] || '',
        given       => $_->[1] || '',
        additional  => $_->[2] || '',
        prefixes    => $_->[3] || '',
        suffixes    => $_->[4] || '',
    } }) };
coerce 'N'
    => from 'Str'
    => via { Text::vCard::Precisely::V3::Node::N->new({ value => [split ';', $_] }) };
has n => ( is => 'rw', isa => 'N', coerce => 1 );

subtype 'Address' => as 'ArrayRef[Text::vCard::Precisely::V3::Node::Address]';
coerce 'Address'
    => from 'HashRef'
    => via { [ Text::vCard::Precisely::V3::Node::Address->new($_) ] };
coerce 'Address'
    => from 'ArrayRef[HashRef]'
    => via { [ map { Text::vCard::Precisely::V3::Node::Address->new($_) } @$_ ] };
has adr => ( is => 'rw', isa => 'Address', coerce => 1 );

subtype 'Tel' => as 'ArrayRef[Text::vCard::Precisely::V3::Node::Phone]';
coerce 'Tel'
    => from 'Str'
    => via { [ Text::vCard::Precisely::V3::Node::Phone->new({ value => $_ }) ] };
coerce 'Tel'
    => from 'HashRef'
    => via { [ Text::vCard::Precisely::V3::Node::Phone->new($_) ] };
coerce 'Tel'
    => from 'ArrayRef[HashRef]'
    => via { [ map { Text::vCard::Precisely::V3::Node::Phone->new($_) } @$_ ] };
has tel => ( is => 'rw', isa => 'Tel', coerce => 1 );

subtype 'Email' => as 'ArrayRef[Text::vCard::Precisely::V3::Node::Email]';
coerce 'Email'
    => from 'Str'
    => via { [ Text::vCard::Precisely::V3::Node::Email->new({ value => $_ }) ] };
coerce 'Email'
    => from 'HashRef'
    => via { [ Text::vCard::Precisely::V3::Node::Email->new($_) ] };
coerce 'Email'
    => from 'ArrayRef[HashRef]'
    => via { [ map { Text::vCard::Precisely::V3::Node::Email->new($_) } @$_ ] };
has email => ( is => 'rw', isa => 'Email', coerce => 1 );

subtype 'URLs' => as 'ArrayRef[Text::vCard::Precisely::V3::Node::URL]';
coerce 'URLs'
    => from 'Str'
    => via {
        my $name = uc [split( /::/, [caller(2)]->[3] )]->[-1];
        return [Text::vCard::Precisely::V3::Node::URL->new({ name => $name, value => $_ })]
    };
coerce 'URLs'
    => from 'HashRef[Str]'
    => via  {
        my $name = uc [split( /::/, [caller(2)]->[3] )]->[-1];
        return [ Text::vCard::Precisely::V3::Node::URL->new({
            name => $name,
            value => $_->{'value'}
        }) ]
    };
coerce 'URLs'
    => from 'Object'    # Can't asign 'URI' or 'Object[URI]'
    => via {
        my $name = uc [split( /::/, [caller(2)]->[3] )]->[-1];
        return [Text::vCard::Precisely::V3::Node::URL->new({
            name => $name,
            value => $_->as_string,
        })]
    };
coerce 'URLs'
    => from 'ArrayRef[HashRef]'
    => via  { [ map{ Text::vCard::Precisely::V3::Node::URL->new($_) } @$_ ] };
has [qw|source sound url fburl caladruri caluri|]
    => ( is => 'rw', isa => 'URLs', coerce => 1 );

subtype 'Image' => as 'ArrayRef[Text::vCard::Precisely::V3::Node::Photo]';
coerce 'Image'
    => from 'HashRef'
    => via  {
        my $name = uc [split( /::/, [caller(2)]->[3] )]->[-1];
        return [ Text::vCard::Precisely::V3::Node::Photo->new({
            name => $name,
            media_type => $_->{'media_type'},
            value => $_->{'value'},
        }) ] };
coerce 'Image'
    => from 'ArrayRef[HashRef]'
    => via  { [ map{ Text::vCard::Precisely::V3::Node::Photo->new($_) } @$_ ] };
coerce 'Image'
    => from 'Object'   # when parse from vCard::Addressbook, URI->new is called.
    => via  { [ Text::vCard::Precisely::V3::Node::Photo->new( { value => $_->as_string } ) ] };
coerce 'Image'
    => from 'Str'   # when parse BASE64 encoded strings
    => via  {
        my $name = uc [split( /::/, [caller(2)]->[3] )]->[-1];
        return [ Text::vCard::Precisely::V3::Node::Photo->new({
            name => $name,
            value => $_,
        } ) ]
    };
coerce 'Image'
    => from 'ArrayRef[Str]'   # when parse BASE64 encoded strings
    => via  {
        my $name = uc [split( /::/, [caller(2)]->[3] )]->[-1];
        return [ map{ Text::vCard::Precisely::V3::Node::Photo->new({
            name => $name,
            value => $_,
        }) } @$_ ]
    };
has [qw| photo logo |] => ( is => 'rw', isa => 'Image', coerce => 1 );

subtype 'SocialProfile' => as 'ArrayRef[Text::vCard::Precisely::V3::Node::SocialProfile]';
coerce 'SocialProfile'
    => from 'HashRef'
    => via { [ Text::vCard::Precisely::V3::Node::SocialProfile->new($_) ] };
coerce 'SocialProfile'
    => from 'ArrayRef[HashRef]'
    => via { [ map { Text::vCard::Precisely::V3::Node::SocialProfile->new($_) } @$_ ] };
has socialprofile => ( is => 'rw', isa => 'SocialProfile', coerce => 1 );

subtype 'Node' => as 'ArrayRef[Text::vCard::Precisely::V3::Node]';
coerce 'Node'
    => from 'Str'
    => via {
        my $name = uc [split( /::/, [caller(2)]->[3] )]->[-1];
        return [ Text::vCard::Precisely::V3::Node->new( { name => $name, value => $_ } ) ]
    };
coerce 'Node'
    => from 'HashRef'
    => via {
        my $name = uc [split( /::/, [caller(2)]->[3] )]->[-1];
        return [ Text::vCard::Precisely::V3::Node->new({
            name => $_->{'name'} || $name,
            types => $_->{'types'} || [],
            value => $_->{'value'} || croak "No value in HashRef!",
        }) ]
    };
coerce 'Node'
    => from 'ArrayRef[HashRef]'
    => via {
        my $name = uc [split( /::/, [caller(2)]->[3] )]->[-1];
        return [ map { Text::vCard::Precisely::V3::Node->new({
            name => $_->{'name'} || $name,
            types => $_->{'types'} || [],
            value => $_->{'value'} || croak "No value in HashRef!",
        }) } @$_ ]
    };
has [qw|fn nickname org impp lang title role categories note xml key geo label related|]
    => ( is => 'rw', isa => 'Node', coerce => 1 );

subtype 'KIND'
    => as 'Str'
    => where { m/^(:?individual|group|org|location|[a-z0-9\-]+|X-[a-z0-9\-]+)$/s }
    => message { "The KIND you provided, $_, was not supported" };
has kind => ( is => 'rw', isa => 'KIND' );

subtype 'TimeStamp'
    => as 'Str'
    => where { m/^\d{4}-\d{2}-\d{2}(:?T\d{2}:\d{2}:\d{2}Z)?$/is  }
    => message { "The TimeStamp you provided, $_, was not correct" };
coerce 'TimeStamp'
    => from 'Int'
    => via {
        my ( $s, $m, $h, $d, $M, $y ) = gmtime($_);
        return sprintf '%4d-%02d-%02dT%02d:%02d:%02dZ', $y + 1900, $M + 1, $d, $h, $m, $s
    };
has rev => ( is => 'rw', isa => 'TimeStamp', coerce => 1  );

subtype 'UID'
    => as 'Str'
    => where { m/^urn:uuid:[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}$/is }
    => message { "The UID you provided, $_, was not correct" };
has uid => ( is => 'rw', isa => 'UID' );

subtype 'MEMBER'
    => as 'ArrayRef[UID]';
coerce 'MEMBER'
    => from 'UID'
    => via { [$_] };
has member => ( is => 'rw', isa => 'MEMBER', coerce => 1 );

subtype 'CLIENTPIDMAP'
    => as 'Str'
    => where { m/^\d+;urn:uuid:[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}$/is }
    => message { "The CLIENTPIDMAP you provided, $_, was not correct" };
subtype 'CLIENTPIDMAPs'
    => as 'ArrayRef[CLIENTPIDMAP]';
coerce 'CLIENTPIDMAPs'
    => from 'Str'
    => via { [$_] };
has clientpidmap => ( is => 'rw', isa => 'CLIENTPIDMAPs', coerce => 1 );

subtype 'TimeZones' => as 'ArrayRef[DateTime::TimeZone]';
coerce 'TimeZones'
    => from 'ArrayRef'
    => via {[ map{ DateTime::TimeZone->new( name => $_ ) } @$_ ]};
coerce 'TimeZones'
    => from 'Str'
    => via {[ DateTime::TimeZone->new( name => $_ ) ]};
has tz =>  ( is => 'rw', isa => 'TimeZones', coerce => 1 );
# utc-offset format is NOT RECOMMENDED in vCard 4.0
# tz can be a URL, but there is no document in RFC2426 and RFC6350

has [qw|bday anniversary gender prodid sort_string|] => ( is => 'rw', isa => 'Str' );

with 'vCard::Role::FileIO';

__PACKAGE__->meta->make_immutable;
no Moose;

sub load_hashref {
    my ( $self, $hashref ) = @_;
    while ( my ( $key, $value ) = each %$hashref ) {
        my $method = $self->can( lc $key );
        next unless $method and $value;
        if ( ref $value eq 'Hash' ) {
            $self->$method( { name => uc($key), %$value } );
        }else{
            $self->$method($value);
        }
    }
    return $self;
}

use vCard::AddressBook;
sub load_file {
    my ( $self, $filename ) = @_;

    my $addressBook = vCard::AddressBook->new({
        encoding_in  => $self->encoding_in,
        encoding_out => $self->encoding_out,
    });
    my $vcard = $addressBook->load_file($filename)->vcards->[0];
    $self->load_hashref($vcard->_data);

    return $self;
}

=head2 load_string($string)

 Returns $self in case you feel like chaining.  This method assumes $string is
 decoded (but not MIME decoded).
=cut

sub load_string {
    my ( $self, $string ) = @_;

    my $addressBook = vCard::AddressBook->new({
        encoding_in  => $self->encoding_in,
        encoding_out => $self->encoding_out,
    });

    my $vcard = $addressBook->load_string($string)->vcards->[0];
    my $data = $vcard->_data;
    $self->load_hashref($data);

    return $self;
}

my @nodes = qw(
    FN N NICKNAME
    ADR LABEL TEL EMAIL IMPP LANG GEO
    ORG TITLE ROLE CATEGORIES RELATED
    NOTE SOUND UID URL FBURL CALADRURI CALURI
    XML KEY SOCIALPROFILE PHOTO LOGO SOURCE
);

sub as_string {
    my ($self) = @_;
    my $string = "BEGIN:VCARD\r\n";
    $string .= 'VERSION:' . $self->version . "\r\n";
    $string .= 'PRODID:' . $self->prodid . "\r\n" if $self->prodid;
    $string .= 'KIND:' . $self->kind . "\r\n" if $self->kind;
    foreach my $node ( @nodes ) {
        my $method = $self->can( lc $node );
        croak "the Method you provided, $node is not supported." unless $method;
        if ( ref $self->$method eq 'ARRAY' ) {
            foreach my $item ( @{ $self->$method } ){
                if ( $item->isa('Text::vCard::Precisely::V3::Node') ){
                    $string .= $item->as_string . "\r\n";
                }elsif($item) {
                    $string .= uc($node) . ":$item\r\n";
                }
            }
        }elsif( $self->$method and $self->$method->isa('Text::vCard::Precisely::V3::Node') ) {
            $string .= $self->$method->as_string . "\r\n";
        }
    }

     $string .= 'SORT-STRING:' . $self->sort_string . "\r\n"
    if $self->version ne '4.0' and $self->sort_string;
    $string .= 'BDAY:' . $self->bday . "\r\n" if $self->bday;
    $string .= 'ANNIVERSARY:' . $self->anniversary . "\r\n" if $self->anniversary;
    $string .= 'GENDER:' . $self->gender . "\r\n" if $self->gender;
    $string .= 'UID:' . $self->uid . "\r\n" if $self->uid;
    map { $string .= "MEMBER:$_\r\n" } @{ $self->member || [] } if $self->member;
    map { $string .= "CLIENTPIDMAP:$_\r\n" } @{ $self->clientpidmap || [] } if $self->clientpidmap;
    map { $string .= "TZ:" . $_->name . "\r\n" } @{ $self->tz || [] } if $self->tz;
    $string .= 'REV:' . $self->rev . "\r\n" if $self->rev;
    $string .= "END:VCARD";

    my $lf = Text::LineFold->new(   # line break with 75bytes
        CharMax => 74,
        Charset => $self->encoding_in,
        OutputCharset => $self->encoding_out,
        Newline => "\r\n",
    );
    $string = $lf->fold( "", " ", $string );
    return decode( $self->encoding_out, $string ) unless $self->encoding_out eq 'none';
    return $string;
}

sub as_file {
    my ( $self, $filename ) = @_;
    my $file = $self->_path($filename);
    $file->spew( $self->_iomode_out, $self->as_string );
    return $file;
}
# Alias
sub address {
    my $self = shift;
    $self->adr(@_);
}

sub fullname {
    my $self = shift;
    $self->fn(@_);
}

sub full_name {
    my $self = shift;
    $self->fn(@_);
}

sub birthday {
    my $self = shift;
    $self->bday(@_);
}

sub timezone {
    my $self = shift;
    $self->tz(@_);
}

1;
