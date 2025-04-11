use strict;
use warnings;
use Test::More;
use PDL;
use PDL::Filter::Biquad;

# Constructor argument checks
eval { PDL::Filter::Biquad->new() };
ok($@,
   'constructor dies without samplerate');

eval { PDL::Filter::Biquad->new(samplerate => 0) };
ok($@,
   'constructor dies with samplerate 0');

# Successful construction
my $filt = PDL::Filter::Biquad->new(samplerate => 44100);
isa_ok($filt, 'PDL::Filter::Biquad');

# Sanity check: filtering a constant signal at 0Hz cutoff
my $input = ones(100);
my $freq  = zeroes(100);
my $output = $filt->process($input, $freq);


ok(all($output < 0.05)->all, 'Lowpass with 0 Hz attenuates to 0');

# Pass-through test at high cutoff (half Nyquist)
$freq .= 22050;
$output = $filt->process($input, $freq);

ok(approx_equal($output->sum / $input->nelem, 1, 0.05), 'High cutoff passes signal nearly unchanged');

done_testing();

sub approx_equal {
    my ($a, $b, $tol) = @_;
    abs($a - $b) <= $tol;
}
