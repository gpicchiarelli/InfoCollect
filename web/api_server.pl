#!/usr/bin/env perl

use Mojolicious::Lite;
use lib './lib';
use db;

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

app->start;
