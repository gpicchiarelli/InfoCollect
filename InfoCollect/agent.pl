#!/usr/bin/env perl

use strict;
use warnings;
use lib "../lib";
use rss_crawler;
use web_crawler;
use Time::HiRes qw(sleep);

my $intervallo = shift @ARGV || 30; # default ogni 30 minuti

print "[Agent] Avvio in modalità automatica. Intervallo: $intervallo minuti\n";

while (1) {
    print "[Agent] Avvio dei crawler...\n";
    rss_crawler::esegui_crawler_rss();
    web_crawler::esegui_crawler_web();
    print "[Agent] Attesa $intervallo minuti prima del prossimo ciclo...\n";
    sleep($intervallo * 60);
}