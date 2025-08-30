use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'InfoCollect',
  VERSION_FROM => undef,
  PREREQ_PM    => {
    'DBI'                    => 0,
    'DBD::SQLite'            => 0,
    'JSON'                   => 0,
    'CryptX'                 => 0, # Crypt::AuthEnc::GCM, Crypt::PK::RSA
    'LWP::UserAgent'         => 0,
    'LWP::Protocol::https'   => 0,
    'IO::Socket::SSL'        => 0,
    'Mozilla::CA'            => 0,
    'XML::RSS'               => 0,
    'Parallel::ForkManager'  => 0,
    'HTML::Tree'             => 0,
    'HTML::Strip'            => 0,
    'Lingua::Identify'       => 0,
    'Lingua::Stem::It'       => 0,
    'Lingua::EN::Tagger'     => 0,
    'Email::Sender::Transport::SMTP' => 0,
    'Text::Template'         => 0,
    'Mojolicious'            => 0,
    'Dancer2'                => 0,
    'Email::Sender'          => 0,
    'Email::Simple'          => 0,
    'XML::Simple'            => 0,
    'File::Slurp'            => 0,
    'Test::Mojo'             => 0,
  },
  test => { TESTS => 't/*.t' },
);

package MY;
sub postamble {
  return <<'MAKE_FRAG';

.PHONY: start
start:
	$(PERL) script/start_all.pl --port 3000

MAKE_FRAG
}
