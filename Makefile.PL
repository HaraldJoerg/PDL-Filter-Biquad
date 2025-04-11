use strict;
use warnings;
use ExtUtils::MakeMaker;
use PDL::Core::Dev;
use utf8;

WriteMakefile(
  NAME                => 'PDL::Filter::Biquad',
  AUTHOR              => 'Harald Jörg <haj@posteo.de>',
  VERSION_FROM        => 'lib/PDL/Filter/Biquad.pd',
  MIN_PERL_VERSION => '5.026',
  LICENSE=> 'perl',
  PREREQ_PM => {
    'PDL'  => '2.096', # deep mode
  },
  CONFIGURE_REQUIRES => {
    'PDL'  => '2.096',
  },
  BUILD_REQUIRES => {
    'PDL'  => '2.096',
  },
  TEST_REQUIRES => {
    'Test::More' => '0.88', # done_testing
    'Test::PDL' => '0.21',
  },
);

{
my @pd_srcs;
package MY; # so that "SUPER" works right
sub init_PM {
  my ($self) = @_;
  $self->SUPER::init_PM;
  @pd_srcs = ::pdlpp_eumm_update_deep($self);
}
sub postamble { ::pdlpp_postamble(@pd_srcs) }
}
