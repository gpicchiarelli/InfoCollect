#!/usr/bin/env perl

use strict;
use warnings;
use lib "../lib";
use rss_crawler;
use web_crawler;

print "Esecuzione combinata RSS + Web...\n";
rss_crawler::esegui_crawler_rss();
web_crawler::esegui_crawler_web();

print "Operazione completata.\n";