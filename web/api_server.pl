#!/usr/bin/env perl

use Mojolicious::Lite;
use lib './lib';
use db;
use rss_crawler;
use web_crawler;
use POSIX qw(getpwuid);

# Token API (da configurare come variabile d'ambiente)
my $api_token = $ENV{'INFOCOLLECT_API_TOKEN'} || die "Token API non configurato.\n";

# Middleware per controllo accesso
under sub {
    my $c = shift;
    my $token = $c->req->headers->header('Authorization');

    # Controllo autenticazione locale
    my $local_user = getpwuid($<);  # Ottiene l'utente corrente
    my $allowed_user = getpwuid($>);  # Ottiene l'utente effettivo
    if ($local_user eq $allowed_user) {
        return 1;
    }

    # Controllo token API
    return $c->render(json => { error => 'Accesso negato' }, status => 401)
        unless $token && $token eq "Bearer $api_token";

    return 1;
};

# Configurazione per servire file statici
app->static->paths->[0] = './web/dist';

# Endpoint per servire l'applicazione React
get '/*any' => { any => '' } => sub {
    my $c = shift;
    $c->reply->static('index.html');
};

# Funzione per registrare log
sub log_activity {
    my ($level, $message) = @_;
    my $dbh = db::connect_db();
    my $sth = $dbh->prepare("INSERT INTO logs (level, message) VALUES (?, ?)");
    $sth->execute($level, $message);
    $sth->finish();
    $dbh->disconnect();
}

# Endpoint per ottenere i feed RSS
get '/api/feeds' => sub {
    my $c = shift;
    log_activity('INFO', 'Accesso a /api/feeds');
    my $feeds = db::get_all_rss_feeds();
    $c->render(json => $feeds);
};

# Endpoint per aggiungere un feed RSS
post '/api/feeds' => sub {
    my $c = shift;
    log_activity('INFO', 'Aggiunta di un feed RSS');
    my $data = $c->req->json;
    db::add_rss_feed($data->{title}, $data->{url});
    $c->render(json => { success => 1 });
};

# Endpoint per ottenere le pagine
get '/api/pages' => sub {
    my $c = shift;
    log_activity('INFO', 'Accesso a /api/pages');
    my $pages = db::get_all_web_urls();
    $c->render(json => $pages);
};

# Endpoint per ottenere le impostazioni
get '/api/settings' => sub {
    my $c = shift;
    log_activity('INFO', 'Accesso a /api/settings');
    my $settings = db::get_all_settings();
    $c->render(json => [ map { { key => $_, value => $settings->{$_} } } keys %$settings ]);
};

# Endpoint per aggiungere una nuova impostazione
post '/api/settings' => sub {
    my $c = shift;
    log_activity('INFO', 'Aggiunta di una nuova impostazione');
    my $data = $c->req->json;
    db::add_setting($data->{key}, $data->{value});
    $c->render(json => { success => 1 });
};

# Endpoint per avviare il crawler RSS
post '/api/crawler/rss' => sub {
    my $c = shift;
    log_activity('INFO', 'Avvio del crawler RSS');
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
    log_activity('INFO', 'Avvio del crawler Web');
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
    log_activity('INFO', 'Accesso a /api/logs');
    my $logs = db::get_logs();  # Funzione da implementare
    $c->render(json => $logs);
};

# Endpoint per ottenere i canali di notifica
get '/api/notification_channels' => sub {
    my $c = shift;
    log_activity('INFO', 'Accesso a /api/notification_channels');
    my $channels = db::get_notification_channels();
    $c->render(json => $channels);
};

# Endpoint per aggiungere un canale di notifica
post '/api/notification_channels' => sub {
    my $c = shift;
    log_activity('INFO', 'Aggiunta di un canale di notifica');
    my $data = $c->req->json;
    db::add_notification_channel($data->{name}, $data->{type}, $data->{config});
    $c->render(json => { success => 1 });
};

# Endpoint per disattivare un canale di notifica
post '/api/notification_channels/:id/deactivate' => sub {
    my $c = shift;
    log_activity('INFO', 'Disattivazione di un canale di notifica');
    my $id = $c->param('id');
    db::deactivate_notification_channel($id);
    $c->render(json => { success => 1 });
};

# Endpoint per ottenere i mittenti
get '/api/senders' => sub {
    my $c = shift;
    my $senders = db::get_all_senders();
    $c->render(json => $senders);
};

# Endpoint per aggiungere un mittente
post '/api/senders' => sub {
    my $c = shift;
    my $data = $c->req->json;
    db::add_sender($data->{name}, $data->{type}, $data->{config});
    $c->render(json => { success => 1 });
};

# Endpoint per ottenere tutti i template
get '/api/templates' => sub {
    my $c = shift;
    my $templates = db::get_all_templates();
    $c->render(json => $templates);
};

# Endpoint per aggiungere un template
post '/api/templates' => sub {
    my $c = shift;
    my $data = $c->req->json;
    db::add_template($data->{name}, $data->{content});
    $c->render(json => { success => 1 });
};

# Endpoint per aggiornare un template
put '/api/templates/:id' => sub {
    my $c = shift;
    my $id = $c->param('id');
    my $data = $c->req->json;
    db::update_template($id, $data->{name}, $data->{content});
    $c->render(json => { success => 1 });
};

# Endpoint per eliminare un template
delete '/api/templates/:id' => sub {
    my $c = shift;
    my $id = $c->param('id');
    db::delete_template($id);
    $c->render(json => { success => 1 });
};

# Endpoint per ottenere i dati di latenza
get '/api/latency' => sub {
    my $c = shift;
    my $dbh = db::connect_db();
    my $sth = $dbh->prepare("SELECT host, latency_ms, last_updated FROM latency_monitor ORDER BY last_updated DESC");
    $sth->execute();
    my @latency_data;
    while (my $row = $sth->fetchrow_hashref) {
        push @latency_data, $row;
    }
    $sth->finish();
    $dbh->disconnect();
    $c->render(json => \@latency_data);
};

# Endpoint per ottenere i dati RSS raccolti
get '/api/rss_data' => sub {
    my $c = shift;
    my $rss_data = db::get_all_rss_data();
    $c->render(json => $rss_data);
};

# Endpoint per ottenere i dati delle pagine web raccolte
get '/api/web_data' => sub {
    my $c = shift;
    my $web_data = db::get_all_web_data();
    $c->render(json => $web_data);
};

# Endpoint per ottenere lo stato della sincronizzazione P2P
get '/api/p2p_status' => sub {
    my $c = shift;
    my $p2p_status = p2p::get_status();  # Funzione da implementare
    $c->render(json => $p2p_status);
};

# Endpoint per aggiungere o aggiornare un'impostazione
post '/api/settings' => sub {
    my $c = shift;
    my $data = $c->req->json;
    db::add_or_update_setting($data->{key}, $data->{value});
    $c->render(json => { success => 1 });
};

# Endpoint per ottenere tutte le impostazioni
get '/api/settings' => sub {
    my $c = shift;
    my $settings = db::get_all_settings();
    $c->render(json => $settings);
};

# Endpoint per inviare un task a un peer
post '/api/send_task' => sub {
    my $c = shift;
    my $data = $c->req->json;
    my $peer_id = $data->{peer_id};
    my $task_data = $data->{task_data};

    eval {
        p2p::send_task($peer_id, $task_data);
        $c->render(json => { success => 1 });
    } or do {
        $c->render(json => { success => 0, error => $@ });
    };
};

app->start;
