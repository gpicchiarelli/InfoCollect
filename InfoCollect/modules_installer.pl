#!/usr/bin/env perl

use strict;
use warnings;

my @modules = qw(
    LWP::UserAgent
    XML::RSS
    HTML::TreeBuilder
    HTML::Strip
    DBI
    DBD::SQLite
    Term::ReadLine
    Term::ANSIColor
    Text::Summarizer
    Lingua::Identify
    Lingua::EN::Tagger
    Lingua::IT::Stemmer
    Text::Extract::Words
    Parallel::ForkManager
    Time::HiRes
);

foreach my $mod (@modules) {
    print "Installazione $mod...\n";
    system("cpanm $mod");
}

print "\nInstallazione completata.\n";