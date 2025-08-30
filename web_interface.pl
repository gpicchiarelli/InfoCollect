#!/usr/bin/env perl

use strict;
use warnings;
use Dancer2;
use lib './lib';
use db;

=pod

=head1 NAME

web_interface.pl - Interfaccia Dancer2 minimale per impostazioni

=head1 DESCRIPTION

Espone una semplice pagina per visualizzare e aggiornare impostazioni.
Fornita come alternativa minimal a Mojolicious, con stesso backend DB.

=cut

get '/' => sub {
    template 'index' => { settings => db::get_all_settings() };
};

post '/update' => sub {
    my $key = body_parameters->get('key');
    my $value = body_parameters->get('value');
    db::set_setting($key, $value);
    redirect '/';
};

start;
