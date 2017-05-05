# ABSTRACT: turns baubles into trinkets
package Text::vCard::Precisely;
$VERSION = 0.02;

use 5.12.5;
use Moose;
use Moose::Util::TypeConstraints;

extends 'Text::vCard::Precisely::V3';

enum 'Version' => [qw( 3.0 4.0 )];
has version => ( is => 'ro', isa => 'Version', default => '3.0', required => 1 );

__PACKAGE__->meta->make_immutable;
no Moose;

sub BUILD {
    my $self = shift;
    return Text::vCard::Precisely::V3->new(@_) unless $self->version eq '4.0';

    require Text::vCard::Precisely::V4;
    return Text::vCard::Precisely::V4->new(@_);
}

1;

=encoding UTF8

=head1 NAME

 Text::vCard::Precisely - Read, Write and Edit the vCards 3.0 and/or 4.0 precisely

=for html <a href="https://travis-ci.org/worthmine/Text-vCard-Precisely"><img src="https://travis-ci.org/worthmine/Text-vCard-Precisely.svg?branch=master"></a>

=head2 SYNOPSIS

    my $vc = Text::vCard::Precisely->new();
    # or now you can write like bellow if you want to use 4.0:
    #my $vc = Text::vCard::Precisely->new( version => '4.0' );

    $vc->n([ 'Gump', 'Forrest', , 'Mr', '' ]);
    $vc->fn( 'Forrest Gump' );

    use GD;
    use MIME::Base64;

    my $img = GD->new( ... some param ... )->plot->png;
    my $base64 = MIME::Base64::encode($img);

    $vc->photo([
        { value => 'https://avatars2.githubusercontent.com/u/2944869?v=3&s=400',  media_type => 'image/jpeg' },
        { value => $img, media_type => 'image/png' }, # Now you can set a binary image directly
        { value => $base64, media_type => 'image/png' }, # Also accept the text encoded in Base64
    ]);

    $vc->org('Bubba Gump Shrimp Co.'); # Now you can set/get org!

    $vc->tel({ value => '+1-111-555-1212', types => ['work'], pref => 1 });

    $vc->email({ value => 'forrestgump@example.com', types => ['work'] });

    $vc->adr( {
        types => ['work'],
        pobox     => '109',
        extended  => 'Shrimp Bld.',
        street    => 'Waters Edge',
        city      => 'Baytown',
        region    => 'LA',
        post_code => '30314,
        country   => 'United States of America',
    });

    $vc->url({ value => 'https://twitter.com/worthmine', types => ['twitter'] }); # for URL param

    use Facebook::Graph;
    use Encode;

    my $fb = Facebook::Graph->new(
        app_id => 'your app id',
        secret => 'your secret key',
    );
    $fb->authorize;
    $fb->access>token( $fb->{'app_id'} . '|' . $fb->{'secret'} );
    my $q = $fb->query->find( 'some facebookID' )
    ->select>fields(qw( id name ))
    ->request
    ->as_hashref;

    $vc->socialprofile({ # Now you can set X-Social-Profile but Android ignore it
        value => 'https://www.facebook/' . 'some facebookID',
        types => 'facebook',
        displayname => encode_utf8( $q->{'name'} ),
        userid => $q->{'id'},
    });

    print $vc->as_string();

=head2 DESCRIPTION

A vCard is a digital business card. vCard and L<Text::vFile::asData|https://github.com/richardc/perl-text-vfile-asdata> provide an API for parsing vCards.

This module is forked from L<Text::vCard|https://github.com/ranguard/text-vcard> because some reason bellow:

=over

=item

Text::vCard B<doesn't provide> full methods based on L<RFC2426|https://tools.ietf.org/html/rfc2426>

=item

Mac OS X and iOS can't parse vCard4.0 with UTF-8 precisely. they cause some Mojibake

=item

Android 4.4.x can't parse vCard4.0


=item

I wanted to learn Moose, of course

=back

To handle an address book with several vCard entries in it, start with
 L<Text::vFile::asData|https://github.com/richardc/perl-text-vfile-asdata> and then come back to this module.

Note that the vCard RFC requires version() and full_name().  This module does not check or warn if these conditions have not been met.

=head2 Constructors

=head3 load_hashref($HashRef)

Accepts an HashRef that looks like below:

 my $hashref = {
    N   => [ 'Gump', 'Forrest', '', 'Mr.', '' ],
    FN  => 'Forrest Gump',
    SORT_STRING => 'Forrest Gump',
    ORG => 'Bubba Gump Shrimp Co.',
    TITLE => 'Shrimp Man',
    PHOTO => { media_type => 'image/gif', value => 'http://www.example.com/dir_photos/my_photo.gif' },
    TEL => [
        { types => ['WORK','VOICE'], value => '(111) 555-1212' },
        { types => ['HOME','VOICE'], value => '(404) 555-1212' },
    ],
    ADR =>[{
        types       => ['work'],
        pref        => 1,
        extended    => 100,
        street      => 'Waters Edge',
        city        => 'Baytown',
        region      => 'LA',
        post_code   => '30314',
        country     => 'United States of America'
    },{
        types       => ['home'],
        extended    => 42,
        street      => 'Plantation St.',
        city        => 'Baytown',
        region      => 'LA',
        post_code   => '30314',
        country     => 'United States of America'
    }],
    URL => 'http://www.example.com/dir_photos/my_photo.gif',
    EMAIL => 'forrestgump@example.com',
    REV => '2008-04-24T19:52:43Z',
 };

=head3 load_file($file_name)

Accepts a file name

=head3 load_string($vCard)

Accepts a vCard string

=head2 METHODS

=head3 as_string()

Returns the vCard as a string.
You have to use Encode::encode_utf8() if your vCard is written in utf8

=head3 as_file($filename)

Write data in vCard format to $filename.
Dies if not successful.

=head2 SIMPLE GETTERS/SETTERS

These methods accept and return strings

=head3 version()

returns Version number of the vcard.  Defaults to B<'3.0'> and this method is B<READONLY>

=head3 rev()

To specify revision information about the current vCard3.0

=head3 sort_string()

To specify the family name, given name or organization text to be used for national-language-specific sorting of the FN, N and ORG
B<This method will be DEPRECATED in vCard4.0> Use SORT-AS param instead of it. (Text::vCard::Precisely::V4 supports it)

=head2 COMPLEX GETTERS/SETTERS

They are based on Moose with coercion.
So these methods accept not only ArrayRef[HashRef] but also ArrayRef[Str], single HashRef or single Str.
Read source if you were confused.

=head3 n()

To specify the components of the name of the object the vCard represents.

=head3 tel()

Accepts/returns an ArrayRef that looks like:

 [
    { type => ['work'], value => '651-290-1234', preferred => 1 },
    { type => ['home'], value => '651-290-1111' },
 ]

=head3 adr(), address()

Accepts/returns an ArrayRef that looks like:

 [
    { types => ['work'], street => 'Main St', pref => 1 },
    { types     => ['home'],
    pobox     => 1234,
    extended  => 'asdf',
    street    => 'Army St',
    city      => 'Desert Base',
    region    => '',
    post_code => '',
    country   => 'USA',
    pref      => 2,
    },
 ]

=head2 email()

Accepts/returns an ArrayRef that looks like:

 [
    { type => ['work'], value => 'bbanner@ssh.secret.army.mil' },
    { type => ['home'], value => 'bbanner@timewarner.com', pref => 1 },
 ]

or accept the string as email like bellow

 'bbanner@timewarner.com'

=head3 url()

Accepts/returns an ArrayRef that looks like:

 [
    { value => 'https://twitter.com/worthmine', types => ['twitter'] },
    { value => 'https://github.com/worthmine' },
 ]

or accept the string as URL like bellow

 'https://github.com/worthmine'

=head3 photo(), logo()

Accepts/returns an ArrayRef of URLs or Images: Even if they are raw image binary or text encoded in Base64, it does not matter.
Attention! Mac OS X and iOS B<ignore> the description beeing URL.
use Base64 encoding or raw image binary if you have to show the image you want.

=head3 note()

To specify supplemental information or a comment that is associated with the vCard

=head3 org(), title(), role(), categories()

To specify additional information for your jobs

=head3 tz(), timezone()

To specify information related to the time zone of the object the vCard represents

=head3 fn(), full_name(), fullname()

A person's entire name as they would like to see it displayed

=head3 nickname()

To specify the text corresponding to the nickname of the object the vCard represents

=head3 bday(), birthday()

To specify the birth date of the object the vCard represents

=head3 source()

To identify the source of directory information contained in the content type

=head3 geo(), prodid(), key(), uid(), sound()

I don't think they are so popular paramater, but here are the methods!

=head2 aroud UTF-8

if you want to send precisely the vCard3.0 with UTF-8 characters to the B<ALMOST> of smartphones, you have to set Charset param for each values like bellow:

 ADR;CHARSET=UTF-8:201号室;マンション;通り;市;都道府県;郵便番号;日本

=head2 for under perl-5.12.5

This module uses C<\P{ascii}> in regexp so You have to use 5.12.5 and later.
And this module uses Data::Validate::URI and it has bug on 5.8.x. so I can't support them.

=head2 SEE ALOSO

=over

=item

L<RFC 2426|https://tools.ietf.org/html/rfc2426>

=item

L<RFC 2425|https://tools.ietf.org/html/rfc2425>

=item

L<Text::vFile::asData|https://github.com/richardc/perl-text-vfile-asdata>

=item

L<README-v4.md|https://github.com/worthmine/Text-vCard-Precisely/blob/master/README-v4.md>

=back

=head2 AUTHOR

L<Yuki Yoshida(worthmine)|https://github.com/worthmine>