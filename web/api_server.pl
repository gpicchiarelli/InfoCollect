#!/usr/bin/env perl

use Mojolicious::Lite;
use lib './lib';
use db;
use rss_crawler;
use web_crawler;
use opml;

# Pagina principale
get '/' => sub {
    my $c = shift;
    $c->render(template => 'index');
};

# Gestione feed RSS
get '/rss_feeds' => sub {
    my $c = shift;
    my $feeds = db::get_all_rss_feeds();
    $c->stash(feeds => $feeds);
    $c->render(template => 'rss_feeds');
};

post '/rss_feeds' => sub {
    my $c = shift;
    my $title = $c->param('title');
    my $url = $c->param('url');
    db::add_rss_feed($title, $url);
    $c->redirect_to('/rss_feeds');
};

# Gestione URL web
get '/web_urls' => sub {
    my $c = shift;
    my $urls = db::get_all_web_urls();
    $c->stash(urls => $urls);
    $c->render(template => 'web_urls');
};

post '/web_urls' => sub {
    my $c = shift;
    my $url = $c->param('url');
    db::add_web_url($url);
    $c->redirect_to('/web_urls');
};

# Gestione impostazioni
get '/settings' => sub {
    my $c = shift;
    my $settings = db::get_all_settings();
    $c->stash(settings => $settings);
    $c->render(template => 'settings');
};

post '/settings' => sub {
    my $c = shift;
    my $key = $c->param('key');
    my $value = $c->param('value');
    db::add_or_update_setting($key, $value);
    $c->redirect_to('/settings');
};

# Gestione riassunti
get '/summaries' => sub {
    my $c = shift;
    my $summaries = db::get_all_summaries();
    $c->stash(summaries => $summaries);
    $c->render(template => 'summaries');
};

# Gestione canali di notifica
get '/notifications' => sub {
    my $c = shift;
    my $channels = db::get_notification_channels();
    $c->stash(channels => $channels);
    $c->render(template => 'notifications');
};

post '/notifications' => sub {
    my $c = shift;
    my $name = $c->param('name');
    my $type = $c->param('type');
    my $config = $c->param('config');
    db::add_notification_channel($name, $type, $config);
    $c->redirect_to('/notifications');
};

# Gestione mittenti
get '/senders' => sub {
    my $c = shift;
    my $senders = db::get_all_senders();
    $c->stash(senders => $senders);
    $c->render(template => 'senders');
};

post '/senders' => sub {
    my $c = shift;
    my $name = $c->param('name');
    my $type = $c->param('type');
    my $config = $c->param('config');
    db::add_sender($name, $type, $config);
    $c->redirect_to('/senders');
};

# Avvio dei crawler
post '/crawler/rss' => sub {
    my $c = shift;
    rss_crawler::esegui_crawler_rss();
    $c->redirect_to('/');
};

post '/crawler/web' => sub {
    my $c = shift;
    web_crawler::esegui_crawler_web();
    $c->redirect_to('/');
};

app->start;
