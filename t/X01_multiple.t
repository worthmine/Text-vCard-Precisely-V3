use strict;
use warnings;

use Test::More tests => 7;
use Path::Tiny qw(path);
use Data::Dumper qw(Dumper);
use lib qw(./lib);

BEGIN { use_ok ('Text::vCard::Precisely::Multiple') };                          # 1
my $vcm = new_ok('Text::vCard::Precisely::Multiple');                           # 2

$vcm->load_file(path( 't', 'Multiple', 'example.vcf' ));
foreach my $vc ( $vcm->all_options() ){
    #note $vc->as_string();
    $vc->fn()->[0] =~ /^FN:(\w+)/;
    is $vc->isa('Text::vCard::Precisely'), 1, "loading vCard for $1 succeeded."; # 3-7
}



done_testing;
