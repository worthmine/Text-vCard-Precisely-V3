package Text::vCard::Precisely::Multiple;

our $VERSION = '0.18';

use Moose;
use Moose::Util::TypeConstraints;

use Carp;
use Text::vCard::Precisely;
use Text::vFile::asData;
my $vf = Text::vFile::asData->new;
use Path::Tiny;

enum 'Version' => [qw( 3.0 4.0 )];
has version => ( is => 'ro', isa => 'Version', default => '3.0', required => 1 );

subtype 'vCards' => as 'ArrayRef[Text::vCard::Precisely]';
coerce 'vCards',
    from 'Text::vCard::Precisely',
    via {[ $_[0] ]};
has options => (
    traits  => ['Array'],
    is => 'ro',
    isa => 'vCards',
    coerce => 1,
    default => sub { [] },
    handles => {
        all_options    => 'elements',
        add_option     => 'push',
        clear_options  => 'clear',
#        map_options    => 'map',
#        filter_options => 'grep',
#        find_option    => 'first',
#        get_option     => 'get',
#        join_options   => 'join',
        count_options  => 'count',
#        has_options    => 'count',
        has_no_options => 'is_empty',
#        sorted_options => 'sort',
    },
);


__PACKAGE__->meta->make_immutable;
no Moose;

sub load_arrayref {
    my $self = shift;
    my $ref = shift;
    croak "Attribute must be an ArrayRef: $ref" unless ref($ref) eq 'ARRAY';
    $self->clear_options();
    
    foreach my $data (@$ref){
        my $vc = Text::vCard::Precisely->new( version => $self->version() );
        $self->add_option( $vc->load_hashref($data) );
    }
    return $self;
}

sub load_file {
    my $self = shift;
    my $filename = shift;
    open my $vcf, "<", $filename or croak "couldn't open vcf: $!";
    my $objects = $vf->parse($vcf)->{'objects'};
    close $vcf;
    
    $self->clear_options();
    foreach my $data (@$objects){
        croak "$filename contains unvalid vCard data." unless $data->{'type'} eq 'VCARD';
        my $vc = Text::vCard::Precisely->new( version => $self->version() );
        my $hashref = $vc->_make_hashref($data);
        $self->add_option( $vc->load_hashref($hashref) );
    }
    return $self;
}

sub as_string {
    my $self = shift;
    my $str = '';
    foreach my $vc ( $self->all_options() ){
       $str .= $vc->as_string();
    }
    return $str;
}

sub as_file {
    my ( $self, $filename ) = @_;
    croak "No filename was set!" unless $filename;
    
    my $file = path($filename);
    $file->spew( {binmode => ":encoding(UTF-8)"}, $self->as_string() );
    return $file;
}

1;

__END__

