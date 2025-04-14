use 5.026;
use FindBin;
use lib "$FindBin::Bin/lib";
use Benchmark qw( cmpthese );
use PDL;
use Test::More;
use Test::PDL;

use BiquadPP;
use PDL::Filter::Biquad;

my $repeat = $ARGV[0] || 100;

# -------- prepare data (using PDL) -------
use constant PI => atan2(0,-1);
my $rate = 48000;
my $n_samples = 48000;
my $frequency = 261; # "Middle C"
my $seq = sequence($n_samples) * (2 * PI * $frequency / $n_samples);
my $data = zeroes($n_samples);
my $cutoff = $data->xlinvals(20000,$frequency);
for my $overtone (1..10) {
    $data += sin($overtone * $seq);
}
my @cutoff = $cutoff->list;
my @data   = $data->list;
my $output;
my %output;

sub class_perl {
    my $filter = Biquad::Class->new(samplerate => 48000,
                                    cutoff => \@cutoff,
                                );
    $output{class_perl} = [$filter->process(\@data,\@cutoff)];
}

sub faster_perl {
    my $filter = BiquadPP->new(samplerate => 48000,
                               cutoff => \@cutoff,
                           );
    $output{faster_perl} = [$filter->process(\@data,\@cutoff)];
}

sub pure_perl {
    my @output = ();
    my $filter = BiquadPP->new(samplerate => 48000,
                               cutoff => $cutoff[0],
                           );
    for my $index (0..$#data) {
        $filter->set_cutoff($cutoff[$index]);
        push @output,$filter->process_sample($data[$index]);
    }
    $output{pure_perl} = \@output;
}

sub filter_pdl {
    my $filter = PDL::Filter::Biquad->new(samplerate => 48000);
    $output = $filter->process($data,$cutoff);
}

use PDL::Graphics::Simple;
cmpthese($repeat,
         {
             'Hash object, loop per sample'   => \&pure_perl,
             'Hash object, bulk samples'      => \&faster_perl,
             '"feature class", bulk samples'  => \&class_perl,
             'PDL::PP'                        => \&filter_pdl,
         }
);

is_pdl(pdl($output{faster_perl}),pdl($output{pure_perl}),
       'Faster Perl and Pure Perl have the same result');
is_pdl(pdl($output{faster_perl}),pdl($output{class_perl}),
       'Faster Perl and Class Perl have the same result');
is_pdl(pdl($output{faster_perl}),$output,
       'Faster Perl and PDL::PP have the same result');

done_testing;

