
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Automagically dispatches subs to XML::Parser::Expat handlers",
  "AUTHOR" => "Patrick Seebauer <patpatpat\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "XML-Parser-Expat-Dispatched",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "XML::Parser::Expat::Dispatched",
  "PREREQ_PM" => {
    "XML::Parser::Expat" => 0
  },
  "TEST_REQUIRES" => {},
  "VERSION" => "0.9",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "XML::Parser::Expat" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



