#!/usr/bin/perl -w

use strict;
use Test::More tests => 14;
use Devel::Peek qw(Dump);
use Devel::SizeMe ':all';

sub zwapp;
sub swoosh($$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$);
sub crunch {
}

my $whack_size = total_size(\&whack);
my $zwapp_size = total_size(\&zwapp);
my $swoosh_size = total_size(\&swoosh);
my $crunch_size = total_size(\&crunch);

cmp_ok($whack_size, '>', 0, 'CV generated at runtime has a size');
if ($] < 5.017) { # blead 186a5ba82d5844e9713475c494fcd6682968609f
    cmp_ok($zwapp_size, '==', $whack_size,
        'CV stubbed at compiletime is same size (CvOUTSIDE is set but not followed)')
            or do { Dump(\&zwapp); Dump(\&whack) };
}
else { pass() }
cmp_ok(length prototype \&swoosh, '>', 0, 'prototype has a length');
cmp_ok($swoosh_size, '>', $zwapp_size + length prototype \&swoosh,
       'prototypes add to the size');
cmp_ok($crunch_size, '>', $zwapp_size, 'sub bodies add to the size');

my $anon_proto = sub ($$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$) {};
my $anon_size = total_size(sub {});
my $anon_proto_size = total_size($anon_proto);
cmp_ok($anon_size, '>', 0, 'anonymous subroutines have a size');
cmp_ok(length prototype $anon_proto, '>', 0, 'prototype has a length');
cmp_ok($anon_proto_size, '>', $anon_size + length prototype $anon_proto,
       'prototypes add to the size');

SKIP: {
    use vars '@b';
    my $aelemfast_lex = total_size(sub {my @a; $a[0]});
    my $aelemfast = total_size(sub {my @a; $b[0]});

    # This one is sane even before Dave's lexical aelemfast changes:
    cmp_ok($aelemfast_lex, '>', $anon_size,
	   'aelemfast for a lexical is handled correctly');
    skip('alemfast was extended to lexicals after this perl was released', 1)
      if $] < 5.008004;
    cmp_ok($aelemfast, '>', $aelemfast_lex,
	   'aelemfast for a package variable is larger');
}

my $short_pvop = total_size(sub {goto GLIT});
my $long_pvop = total_size(sub {goto KREEK_KREEK_CLANK_CLANK});
cmp_ok($short_pvop, '>', $anon_size, 'OPc_PVOP can be measured');
is($long_pvop, $short_pvop + 19, 'the only size difference is the label length');

my $short_padname = total_size(sub { my $x = 1; return $x; });
my $long_padname = total_size(sub {
    my $lexical_name_long_enough_to_measure = 1;
    return $lexical_name_long_enough_to_measure;
});
cmp_ok($long_padname, '>', $short_padname, 'pad name storage contributes to CV size');

SKIP: {
    if ($] < 5.022) {
        skip('PADNAME structs were introduced in Perl 5.22', 1);
    }

    my $padname_profile = 'test_code_padname.dat';
    unlink $padname_profile;
    {
        local $ENV{SIZEME} = $padname_profile;
        my $outer = 1;
        my $closure = sub { return $outer; };
        total_size($closure);
    }
    open(my $padname_fh, '<', $padname_profile) or BAIL_OUT("Unable to read $padname_profile: $!");
    my $padname_records = grep { / PADNAME$/ } <$padname_fh>;
    close($padname_fh) or BAIL_OUT("Unable to close $padname_profile: $!");
    is($padname_records, 2, 'an outer pad name records its proxy and owning allocation');
    unlink $padname_profile;
}
