#!/usr/bin/env perl

use Mojolicious::Lite;
use lib './lib';
use db;
use rss_crawler;
use web_crawler;
use opml;
use p2p;
use Mojo::Util qw(slurp);
use notification;

# Serve static files from ./static
app->static->paths->[0] = app->home->rel_file('static');

=pod

=head1 NAME

api_server.pl - Interfaccia web Mojolicious per InfoCollect

=head1 DESCRIPTION

Espone dashboard HTML e API JSON per gestire feed, URL web, impostazioni, riassunti,
notifiche e mittenti. Integra endpoint per l’invio di task P2P e import OPML.
Condivide lo stesso database della console CLI.

Cross-reference: docs/REFERENCE.md (riferimenti generali), lib/db.pm, lib/p2p.pm.

=cut

#
# FUNCTIONS (route handlers)
# - GET /            : dashboard HTML
# - GET/POST /rss_feeds, /web_urls, /settings, /summaries, /notifications, /senders
# - POST /crawler/rss, /crawler/web
# - API JSON: POST /api/send_task, POST /api/import_opml, GET /api/pages
#
# Pagina principale
get '/' => sub {
    my $c = shift;
    $c->render(template => 'index');
};

# Elenco documentazione disponibile
get '/docs' => sub {
    my $c = shift;
    my @docs = (
        { name => 'README',     file => 'README.md' },
        { name => 'SETUP',      file => 'docs/SETUP.md' },
        { name => 'CLI',        file => 'docs/CLI.md' },
        { name => 'REFERENCE',  file => 'docs/REFERENCE.md' },
    );
    $c->render(json => \@docs);
};

# Visualizza un documento per nome
get '/docs/:name' => sub {
    my $c = shift;
    my $name = uc($c->param('name') // 'README');
    my %map = (
        README    => 'README.md',
        SETUP     => 'docs/SETUP.md',
        CLI       => 'docs/CLI.md',
        REFERENCE => 'docs/REFERENCE.md',
    );
    my $file = $map{$name};
    return $c->reply->not_found unless $file && -e $file;
    my $content = slurp($file);
    $c->render(text => $content);
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
    my $connectors = notification::supported_connectors();
    my %templates = map { $_->{type} => notification::default_config_template($_->{type}) } @$connectors;
    $c->stash(senders => $senders, connectors => $connectors, templates => \%templates);
    $c->render(template => 'senders');
};

post '/senders' => sub {
    my $c = shift;
    my $name = $c->param('name');
    my $type = $c->param('type');
    my $config = $c->param('config');
    my ($ok,$err) = notification::validate_config($type, $config);
    if (!$ok) {
        $c->flash(notice => "Config non valida: $err");
        return $c->redirect_to('/senders');
    }
    db::add_sender($name, $type, $config);
    $c->flash(notice => "Mittente aggiunto: $name ($type)");
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

# Connettori: elenco e validazione
get '/connectors' => sub {
    my $c = shift;
    my $list = notification::supported_connectors();
    $c->stash(connectors => $list);
    $c->render(template => 'connectors');
};

get '/connectors.json' => sub {
    my $c = shift;
    $c->render(json => notification::supported_connectors());
};

post '/connectors/:type/validate' => sub {
    my $c = shift;
    my $type = $c->param('type');
    my $config = $c->param('config') || $c->req->json;
    my ($ok, $err) = notification::validate_config($type, $config);
    return $c->render(json => { ok => JSON::true }) if $ok;
    $c->render(json => { ok => JSON::false, error => $err }, status => 400);
};

post '/connectors/:type/validate_form' => sub {
    my $c = shift;
    my $type = $c->param('type');
    my $config = $c->param('config');
    my ($ok, $err) = notification::validate_config($type, $config);
    $c->flash(notice => $ok ? "Config valida per $type" : "Config NON valida per $type: $err");
    $c->redirect_to('/connectors');
};

# Test invio tramite mittente (account) esistente
post '/senders/:id/test' => sub {
    my $c = shift;
    my $id = $c->param('id');
    my $msg = $c->param('message') // 'Messaggio di test da InfoCollect';
    my $senders = db::get_all_senders();
    my ($s) = grep { $_->{id} == $id } @$senders;
    return $c->reply->not_found unless $s;
    eval { notification::send_notification($s, $msg) };
    if ($@) {
        return $c->render(json => { success => 0, error => "$@" }, status => 500);
    }
    $c->render(json => { success => 1 });
};

# Test via form: redirect + flash
post '/senders/:id/test_form' => sub {
    my $c = shift;
    my $id = $c->param('id');
    my $msg = $c->param('message') // 'Messaggio di test da InfoCollect';
    my $senders = db::get_all_senders();
    my ($s) = grep { $_->{id} == $id } @$senders;
    unless ($s) { return $c->redirect_to('/senders'); }
    eval { notification::send_notification($s, $msg) };
    if ($@) {
        $c->flash(notice => "Errore nell'invio: $@");
    } else {
        $c->flash(notice => "Messaggio di test inviato (ID=$id)");
    }
    $c->redirect_to('/senders');
};

app->start;
