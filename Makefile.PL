use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME   => 'Daedalus::Hermes',
    AUTHOR => q{Álvaro Castellano Vela <alvaro.castellano.vela@gmail.com>},
    VERSION_FROM       => 'lib/Daedalus/Hermes.pm',
    ABSTRACT_FROM      => 'lib/Daedalus/Hermes.pm',
    LICENSE            => 'gpl_3',
    PL_FILES           => {},
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {

        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
    },
    (
        eval { ExtUtils::MakeMaker->VERSION(6.46) }
        ? (
            META_MERGE => {
                'meta-spec' => { version => 2 },
                resources   => {
                    repository => {
                        type => 'git',
                        url =>
'https://git.daedalus-project.io/daedalusproject/Hermes-Perl.git',
                        web =>
'https://git.daedalus-project.io/daedalusproject/Hermes-Perl',
                    },
                }
            }
          )
        : ()
    ),
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Daedalus-Hermes-*' },
);
