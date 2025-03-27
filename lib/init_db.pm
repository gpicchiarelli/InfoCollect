#!/usr/bin/env perl

use strict;
use warnings;
use DBI;

my $db_file = "infocollect.db";
my $dbh = DBI->connect("dbi:SQLite:dbname=$db_file", "", "", {
    RaiseError => 1,
    AutoCommit => 1,
});

print "Inizializzazione database '$db_file'...\n";

# Tabella feed RSS
$dbh->do(q{
    CREATE TABLE IF NOT EXISTS rss_feeds (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        url TEXT NOT NULL UNIQUE,
        added_at TEXT DEFAULT CURRENT_TIMESTAMP
    )
});
$dbh->do(q{CREATE INDEX IF NOT EXISTS idx_rss_feeds_url ON rss_feeds (url)});

# Tabella articoli RSS
$dbh->do(q{
    CREATE TABLE IF NOT EXISTS rss_articles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        feed_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        url TEXT NOT NULL UNIQUE,
        published_at TEXT,
        content TEXT,
        author TEXT,
        FOREIGN KEY(feed_id) REFERENCES rss_feeds(id) ON DELETE CASCADE
    )
});
$dbh->do(q{CREATE INDEX IF NOT EXISTS idx_rss_articles_feed_id ON rss_articles (feed_id)});

# Tabella pagine raccolte
$dbh->do(q{
    CREATE TABLE IF NOT EXISTS pages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        url TEXT NOT NULL UNIQUE,
        title TEXT,
        content TEXT,
        metadata TEXT,
        visited_at TEXT DEFAULT CURRENT_TIMESTAMP
    )
});
$dbh->do(q{CREATE INDEX IF NOT EXISTS idx_pages_url ON pages (url)});

# Tabella impostazioni
$dbh->do(q{
    CREATE TABLE IF NOT EXISTS settings (
        key TEXT PRIMARY KEY,
        value TEXT
    )
});

# Tabella riassunti associati a pagine
$dbh->do(q{
    CREATE TABLE IF NOT EXISTS summaries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        page_id INTEGER NOT NULL,
        summary TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY(page_id) REFERENCES pages(id) ON DELETE CASCADE
    )
});
$dbh->do(q{CREATE INDEX IF NOT EXISTS idx_summaries_page_id ON summaries (page_id)});

# Tabella autori (opzionale per metadati estesi)
$dbh->do(q{
    CREATE TABLE IF NOT EXISTS authors (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT,
        affiliation TEXT
    )
});

# Tabella web per gestire crawling diretto su siti
$dbh->do(q{
    CREATE TABLE IF NOT EXISTS web (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        url TEXT NOT NULL UNIQUE,
        attivo INTEGER DEFAULT 1
    )
});
$dbh->do(q{CREATE INDEX IF NOT EXISTS idx_web_url ON web (url)});

print "Database inizializzato correttamente.\n";

$dbh->disconnect or warn "Errore durante la disconnessione dal database: $DBI::errstr";