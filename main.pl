#!/usr/bin/perl
use strict;
use warnings;
use lib './lib';
use AppConfig;
use Database;
use RequestHandler;
use Server;

# Инициализация компонентов
my $config = AppConfig->new;
my $database = Database->new($config);
my $handler = RequestHandler->new($config);
my $server = Server->new($config, $handler);

# Инициализация базы данных
$database->init;

# Запуск сервера
$server->start;
