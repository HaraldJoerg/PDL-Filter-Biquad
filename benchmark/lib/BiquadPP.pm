# ABSTRACT: A Biquad filter for real-time application
package BiquadPP;
use 5.038;

use strict;
use warnings;
use constant PI => atan2(0,-1);

sub new {
    my ($class, %opts) = @_;
    my $self = {
        samplerate => $opts{samplerate} || 48000,
        cutoff     => $opts{cutoff} || 1000,    # Hz
        q          => $opts{q} || 1/sqrt(2),    # Q factor (1/sqrt(2) = no resonance)
        a0 => 0, a1 => 0, a2 => 0,
        b1 => 0, b2 => 0,
        z1 => 0, z2 => 0,  # Delay buffers (y[n-1], y[n-2])
    };
    bless $self, $class;
    $self->_recalculate();
    return $self;
}

sub set_cutoff {
    my ($self, $cutoff) = @_;
    $self->{cutoff} = $cutoff;
    $self->_recalculate();
}

sub set_q {
    my ($self, $q) = @_;
    $self->{q} = $q;
    $self->_recalculate();
}

sub _recalculate {
    my ($self) = @_;
    my $sr = $self->{samplerate};
    my $fc = $self->{cutoff};
    my $q  = $self->{q};
    my $w0 = 2 * PI * $fc / $sr;

    my $alpha = sin($w0) / (2 * $q);

    my $cos_w0 = cos($w0);

    my $b0 = (1 - $cos_w0) / 2;
    my $b1 = 1 - $cos_w0;
    my $b2 = $b0;
    my $a0 = 1 + $alpha;
    my $a1 = -2 * $cos_w0;
    my $a2 = 1 - $alpha;

    # Normalize coefficients
    $self->{a1} = $a1 / $a0;
    $self->{a2} = $a2 / $a0;
    $self->{b0} = $b0 / $a0;
    $self->{b1} = $b1 / $a0;
    $self->{b2} = $b2 / $a0;
}

sub process_sample {
    my ($self, $x) = @_;

    my $y       = $self->{b0} * $x + $self->{z1};
    $self->{z1} = $self->{b1} * $x + $self->{z2} - $self->{a1} * $y;
    $self->{z2} = $self->{b2} * $x               - $self->{a2} * $y;

    return $y;
}


sub process {
    my ($self,$data,$cutoff) = @_;
    my $sr = $self->{samplerate};
    my $q  = $self->{q};
    my @output;
    for my $index (0 .. $#$data) {
        my $fc = $cutoff->[$index];
        my $x  = $data->[$index];

        # recalculate coefficients
        my $w0 = 2 * PI * $fc / $sr;

        my $alpha = sin($w0) / (2 * $q);

        my $cos_w0 = cos($w0);

        my $b0 = (1 - $cos_w0) / 2;
        my $b1 = 1 - $cos_w0;
        my $b2 = $b0;
        my $a0 = 1 + $alpha;
        my $a1 = -2 * $cos_w0;
        my $a2 = 1 - $alpha;

        # Normalize coefficients
        $self->{a1} = $a1 / $a0;
        $a2 = $a2 / $a0;
        $self->{b0} = $b0 / $a0;
        $self->{b1} = $b1 / $a0;
        $self->{b2} = $b2 / $a0;

        my $y       = $self->{b0} * $x + $self->{z1};
        $self->{z1} = $self->{b1} * $x + $self->{z2} - $self->{a1} * $y;
        $self->{z2} = $self->{b2} * $x               - $a2 * $y;

        push @output,$y;
    }
    return @output;
}

######################################################################
use feature 'class';
no warnings 'experimental';
class Biquad::Class;

use constant PI => atan2(0,-1);

field $samplerate :param = 48000;
field $cutoff     :param = 1000;
field $q          :param = 1/sqrt(2);

field $a1;
field $a2;
field $b0;
field $b1;
field $b2;
field $z1 = 0;
field $z2 = 0;

method process ($data,$cutoff) {
    my @output;
    for my $index (0 .. $#$data) {
        my $fc = $cutoff->[$index];
        my $x  = $data->[$index];

        # recalculate coefficients
        my $w0 = 2 * PI * $fc / $samplerate;

        my $alpha = sin($w0) / (2 * $q);

        my $cos_w0 = cos($w0);

        $b0 = (1 - $cos_w0) / 2;
        $b1 = 1 - $cos_w0;
        $b2 = $b0;
        $a1 = -2 * $cos_w0;
        $a2 = 1 - $alpha;

        # Normalize coefficients
        my $a0 = 1 + $alpha;
        $a1 = $a1 / $a0;
        $a2 = $a2 / $a0;
        $b0 = $b0 / $a0;
        $b1 = $b1 / $a0;
        $b2 = $b2 / $a0;

        my $y = $b0 * $x + $z1;
        $z1   = $b1 * $x + $z2 - $a1 * $y;
        $z2   = $b2 * $x       - $a2 * $y;

        push @output,$y;
    }
    return @output;
}


1;
