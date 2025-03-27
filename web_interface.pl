#!/usr/bin/env perl

use strict;
use warnings;
use Dancer2;
use lib './lib';
use db;

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
