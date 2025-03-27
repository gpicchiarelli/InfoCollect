#!/usr/bin/env perl

use Mojolicious::Lite;
use lib './lib';
use db;

get '/' => sub {
    my $c = shift;
    eval {
        $c->render(template => 'index');
    };
    if ($@) {
        $c->render(text => "Errore interno del server: $@", status => 500);
    }
};

app->start;

__DATA__

@@ index.html.ep
<!DOCTYPE html>
<html>
<head>
    <title>InfoCollect</title>
</head>
<body>
    <h1>InfoCollect - Interfaccia Web</h1>
    <form method="POST" action="/api/crawler/rss">
        <button type="submit">Avvia Crawler RSS</button>
    </form>
    <form method="POST" action="/api/crawler/web">
        <button type="submit">Avvia Crawler Web</button>
    </form>
</body>
</html>
