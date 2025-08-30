#!/usr/bin/env perl

use Mojolicious::Lite;
use lib './lib';
use db;
use rss_crawler;
use web_crawler;
use opml;
use p2p;

=pod

=head1 NAME

api_server.pl - Interfaccia web Mojolicious per InfoCollect

=head1 DESCRIPTION

Espone dashboard HTML e API JSON per gestire feed, URL web, impostazioni, riassunti,
notifiche e mittenti. Integra endpoint per l’invio di task P2P e import OPML.
Condivide lo stesso database della console CLI.

Cross-reference: docs/REFERENCE.md (riferimenti generali), lib/db.pm, lib/p2p.pm.

=cut

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

# API: invio task a peer
post '/api/send_task' => sub {
    my $c = shift;
    my $peer_id   = $c->req->json // {};
    my $peer      = $peer_id->{peer_id};
    my $task_data = $peer_id->{task_data};
    eval { p2p::send_task($peer, $task_data) };
    if ($@) {
        return $c->render(json => { success => 0, error => "$@" }, status => 500);
    }
    $c->render(json => { success => 1 });
};

# API: import OPML
post '/api/import_opml' => sub {
    my $c = shift;
    my $file_path = $c->param('file_path');
    eval { opml::import_opml($file_path) };
    if ($@) {
        return $c->render(json => { success => 0, error => "$@" }, status => 500);
    }
    $c->render(json => { success => 1 });
};

# API: elenco pagine
get '/api/pages' => sub {
    my $c = shift;
    my $pages = db::get_all_web_data();
    $c->render(json => $pages);
};

app->start;
