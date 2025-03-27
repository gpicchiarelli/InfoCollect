#!/usr/bin/env perl

use Mojolicious::Lite;
use lib './lib';
use db;
use rss_crawler;
use web_crawler;

# Endpoint per ottenere i feed RSS
get '/api/feeds' => sub {
    my $c = shift;
    my $feeds = db::get_all_rss_feeds();
    $c->render(json => $feeds);
};

# Endpoint per aggiungere un feed RSS
post '/api/feeds' => sub {
    my $c = shift;
    my $data = $c->req->json;
    db::add_rss_feed($data->{title}, $data->{url});
    $c->render(json => { success => 1 });
};

# Endpoint per ottenere le pagine
get '/api/pages' => sub {
    my $c = shift;
    my $pages = db::get_all_web_urls();
    $c->render(json => $pages);
};

# Endpoint per ottenere le impostazioni
get '/api/settings' => sub {
    my $c = shift;
    my $settings = db::get_all_settings();
    $c->render(json => [ map { { key => $_, value => $settings->{$_} } } keys %$settings ]);
};

# Endpoint per aggiungere una nuova impostazione
post '/api/settings' => sub {
    my $c = shift;
    my $data = $c->req->json;
    db::add_setting($data->{key}, $data->{value});
    $c->render(json => { success => 1 });
};

# Endpoint per avviare il crawler RSS
post '/api/crawler/rss' => sub {
    my $c = shift;
    eval { rss_crawler::esegui_crawler_rss(); };
    if ($@) {
        $c->render(json => { success => 0, error => $@ });
    } else {
        $c->render(json => { success => 1 });
    }
};

# Endpoint per avviare il crawler Web
post '/api/crawler/web' => sub {
    my $c = shift;
    eval { web_crawler::esegui_crawler_web(); };
    if ($@) {
        $c->render(json => { success => 0, error => $@ });
    } else {
        $c->render(json => { success => 1 });
    }
};

# Endpoint per ottenere i log
get '/api/logs' => sub {
    my $c = shift;
    my $logs = db::get_logs();  # Funzione da implementare
    $c->render(json => $logs);
};

app->start;
