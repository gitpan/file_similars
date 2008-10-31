use strict;
use warnings;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME		=> 'File::Searcher::Similars',
    AUTHOR              => 'Tong Sun <suntong@cpan.org>',
    VERSION_FROM	=> 'Similars.pm', # finds $VERSION
    ABSTRACT_FROM       => 'Similars.pm',
    EXE_FILES		=> [ 'fileSimilars.pl' ],
    PL_FILES            => {},
    PREREQ_PM => {
     'Class::Accessor'	=> 0,
     'Test::More'	=> 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'File-Similars-*' },
);
