use strict;
use warnings;
use Test::More;
use Test::PDL;
use PDL;
use PDL::FFT;

use PDL::Filter::Biquad;
use constant PI => atan2(0,-1);

sub white_noise {
    my ($n_samples) = @_;
    my $bandwidth = $n_samples/2;
    PDL::srandom(0);
    my $phase = random($bandwidth) * (2*PI);
    my $cos   = cos($phase);
    my $sin   = sin($phase);
    my $spectrum = zeroes(2*$bandwidth);
    $spectrum->slice([0,$bandwidth-1]) .= $cos;
    $spectrum->slice([$bandwidth,-1])  .= $sin;
    $spectrum->realifft;
    $spectrum /= $spectrum->abs->max;
    return $spectrum;
}

sub power {
    my $samples = shift;
    my $n_samples = $samples->dim(0);
    my $spectrum = $samples->copy;
    $spectrum->realfft;
    my $real = $spectrum->slice([0,$n_samples/2-1]);
    my $imag = $spectrum->slice([$n_samples/2,-1]);
    my $power = 10*log($real*$real + $imag*$imag) / log(10);
    return $power - $power->max;
}

# Constructor argument checks
eval { PDL::Filter::Biquad->new() };
ok($@,
   'Constructor dies without samplerate');

eval { PDL::Filter::Biquad->new(samplerate => 0) };
ok($@,
   'Constructor dies with samplerate 0');

{
    # Successful construction
    my $filter = PDL::Filter::Biquad->new(samplerate => 44100);
    isa_ok($filter, 'PDL::Filter::Biquad');
}

{
    # Sanity check: filtering a constant signal at 0Hz cutoff
    my $filter = PDL::Filter::Biquad->new(samplerate => 44100);
    my $input  = ones(100);
    my $freq   = zeroes(100);
    my $output = $filter->process($input, $freq);
    local $Test::PDL::DEFAULTS{atol} = 1.0E-4;
    is_pdl($output,$freq,
           'Lowpass with 0 Hz attenuates to very low output');
}

{
    # Pass-through test at high cutoff (half Nyquist)
    my $filter = PDL::Filter::Biquad->new(samplerate => 44100,q => 1);
    my $input  = ones(100);
    my $freq   = zeroes(100) + 22050;
    my $output = $filter->process($input, $freq);
    local $Test::PDL::DEFAULTS{atol} = 1.0E-2;
    is_pdl($output,$input,
           'High cutoff passes signal nearly unchanged');
}

# Some variables will persist for more than one test...
my $output_variable;
my $n_samples = 4000;
my $cutoff    = 500;
my $input     = white_noise($n_samples);
{
    # Now for some more serious tests...
    my $filter    = PDL::Filter::Biquad->new(samplerate => $n_samples);
    my $i_pow     = power($input);
    my $freq      = zeroes($n_samples) + $cutoff;
    my $output       = $filter->process($input, $freq);
    my $o_pow     = power($output);
    use PDL::Graphics::Prima::Simple;
    ok(abs($o_pow->at($cutoff)+3) < 0.1,
       'Attenuation at the cutoff frequency is about 3dB')
        or diag "Attenuation at cutoff: ", $o_pow->at($cutoff),
        " (should be -3)";
    my $attenuation_15dB = 10*log(1/2)/log(10);
    ok(abs($o_pow->at(2*$cutoff)+15) < 0.3,
       'Attenuation at twice the cutoff frequency is about 15dB')
        or diag "Attenuation at twice the cutoff: ", $o_pow->at(2*$cutoff)
        . " (should be -15)";
    $output_variable = $output;
}

{
    # Now for some more serious tests...
    my $filter    = PDL::Filter::Biquad->new(samplerate => $n_samples);
    my $i_pow     = power($input);
    my $output    = $filter->process($input, $cutoff);
    my $o_pow     = power($output);
    use PDL::Graphics::Prima::Simple;
    is_pdl($output,$output_variable,
           'Variable cutoff and fixed cutoff give same results');
}

done_testing();
