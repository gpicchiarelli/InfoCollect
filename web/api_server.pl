#!/usr/bin/env perl

use Mojolicious::Lite;
use lib './lib';
use db;
use rss_crawler;
use web_crawler;
use opml;
use p2p;
use Mojo::File qw(path);
use JSON ();
use FindBin;
use config_manager;
use notification;

# App secrets (evita warning passphrase)
my %s = eval { config_manager::get_all_settings() };
app->secrets([ $s{MOJO_SECRET} || 'infocollect_dev_secret' ]);

# Serve static files (accetta esecuzione da qualunque CWD)
# Con richieste come /static/style.css cerchiamo in "$FindBin::Bin/static/style.css"
app->static->paths->[0] = $FindBin::Bin;

# Health and version endpoints
get '/healthz' => sub {
    my $c = shift;
    my ($db_ok, $err) = (JSON::false, undef);
    eval {
        my $dbh = db::connect_db();
        $dbh->do('SELECT 1');
        $db_ok = JSON::true;
    };
    $err = "$@" if $@;
    $c->render(json => { ok => JSON::true, db => $db_ok, error => ($err // '') });
};

get '/version' => sub {
    my $c = shift;
    my %st = eval { config_manager::get_all_settings() };
    my $ver = $st{APP_VERSION} || 'dev';
    my $perl = $];
    my $mojo = $Mojolicious::VERSION;
    $c->render(json => { app => 'InfoCollect', version => $ver, perl => $perl, mojolicious => $mojo });
};

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
    my $content = path($file)->slurp;
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
    $c->flash(notice => 'Feed aggiunto');
    $c->redirect_to('/rss_feeds');
};

post '/rss_feeds/:id/delete' => sub {
    my $c = shift;
    my $id = $c->param('id');
    eval { db::delete_rss_feed($id) };
    $c->flash(notice => $@ ? "Errore eliminazione feed: $@" : 'Feed eliminato');
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
    $c->flash(notice => 'URL aggiunto');
    $c->redirect_to('/web_urls');
};

post '/web_urls/:id/toggle' => sub {
    my $c = shift;
    my $id = $c->param('id');
    my $status = $c->param('status');
    eval { db::update_web_url_status($id, $status) };
    $c->flash(notice => $@ ? "Errore aggiornamento stato: $@" : 'Stato aggiornato');
    $c->redirect_to('/web_urls');
};

post '/web_urls/:id/delete' => sub {
    my $c = shift;
    my $id = $c->param('id');
    eval { db::delete_web_url($id) };
    $c->flash(notice => $@ ? "Errore eliminazione URL: $@" : 'URL eliminato');
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




# Pagine web
get '/pages' => sub {
    my $c = shift;
    my $pages = db::get_all_web_data();
    $c->stash(pages => $pages);
    $c->render(template => 'pages');
};

post '/pages/:id/delete' => sub {
    my $c = shift;
    my $id = $c->param('id');
    eval { db::delete_page($id) };
    $c->flash(notice => $@ ? "Errore eliminazione pagina: $@" : 'Pagina eliminata');
    $c->redirect_to('/pages');
};
# Logs viewer
get '/logs' => sub {
    my $c = shift;
    my $logs = db::get_logs();
    $c->stash(logs => $logs);
    $c->render(template => 'logs');
};

get '/logs.json' => sub {
    my $c = shift;
    $c->render(json => db::get_logs());
};



# Articoli RSS
get '/articles' => sub {
    my $c = shift;
    my $articles = db::get_all_rss_articles();
    $c->stash(articles => $articles);
    $c->render(template => 'articles');
};

post '/articles/:id/delete' => sub {
    my $c = shift;
    my $id = $c->param('id');
    eval { db::delete_rss_article($id) };
    $c->flash(notice => $@ ? "Errore eliminazione articolo: $@" : 'Articolo eliminato');
    $c->redirect_to('/articles');
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

post '/notifications/:id/deactivate' => sub {
    my $c = shift;
    my $id = $c->param('id');
    eval { db::deactivate_notification_channel($id) };
    $c->flash(notice => $@ ? "Errore disattivazione: $@" : 'Canale disattivato');
    $c->redirect_to('/notifications');
};


post '/connectors/:type/check' => sub {
    my $c = shift;
    my $type = $c->param('type');
    my $config = $c->param('config') || $c->req->json;
    my ($ok, $err) = notification::check_connector($type, $config);
    return $c->render(json => { ok => JSON::true }) if $ok;
    $c->render(json => { ok => JSON::false, error => $err }, status => 400);
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

post '/api/export_opml' => sub {
    my $c = shift;
    my $file_path = $c->param('file_path');
    eval { opml::export_opml($file_path) };
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
    if (!$config) {
        my %cfg;
        my ($spec) = grep { $_->{type} eq $type } @{ notification::supported_connectors() };
        if ($spec) {
            for my $k (@{ $spec->{required} }) { my $v = $c->param("field_$k"); $cfg{$k} = $v if defined $v && $v ne '' }
            for my $p ($c->param) { next unless $p =~ /^field_(.+)$/; my $k=$1; $cfg{$k} = $c->param($p) if !exists $cfg{$k} && defined $c->param($p) && $c->param($p) ne '' }
        }
        $config = JSON::encode_json(\%cfg);
    }
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

post '/senders/:id/check' => sub {
    my $c = shift;
    my $id = $c->param('id');
    my $senders = db::get_all_senders();
    my ($s) = grep { $_->{id} == $id } @$senders;
    unless ($s) { return $c->render(json => { ok => JSON::false, error => 'Sender non trovato' }, status => 404); }
    my ($ok,$err) = notification::check_connector($s->{type}, $s);
    return $c->render(json => { ok => JSON::true }) if $ok;
    $c->render(json => { ok => JSON::false, error => $err }, status => 400);
};

post '/senders/:id/delete' => sub {
    my $c = shift;
    my $id = $c->param('id');
    eval { db::delete_sender($id) };
    $c->flash(notice => $@ ? "Errore eliminazione mittente: $@" : 'Mittente eliminato');
    $c->redirect_to('/senders');
};

app->start;
