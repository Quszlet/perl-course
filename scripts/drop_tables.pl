#!/usr/bin/perl
use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use AppConfig;
use Database;
use File::Spec;

print "Удаление таблиц базы данных...\n";

my $project_root = File::Spec->catdir($Bin, '..');

# Создаем конфигурацию с правильным путем
my $config = AppConfig->new;

# Переопределяем путь к базе данных
$config->{db_path} = File::Spec->catfile($project_root, 'data', 'site.db');
my $db = Database->new($config);
my $dbh = $db->connect;

# Устанавливаем таймаут для блокировки и режим ожидания
$dbh->{sqlite_busy_timeout} = 5000; # 5 секунд
$dbh->do('PRAGMA busy_timeout = 5000');
$dbh->do('PRAGMA journal_mode = WAL'); # Write-Ahead Logging для лучшей конкурентности

eval {
    # Отключаем проверку внешних ключей для удаления
    $dbh->do('PRAGMA foreign_keys = OFF');
    
    # Получаем список всех таблиц
    my $tables_sth = $dbh->prepare(q{
        SELECT name FROM sqlite_master 
        WHERE type='table' 
        AND name NOT LIKE 'sqlite_%'
    });
    $tables_sth->execute();
    
    # Удаляем каждую таблицу
    while (my ($table_name) = $tables_sth->fetchrow_array()) {
        print "Удаление таблицы $table_name...\n";
        eval {
            $dbh->do("DROP TABLE IF EXISTS $table_name");
            if ($@) {
                print "Ошибка при удалении таблицы $table_name: $@\n";
                # Продолжаем с следующей таблицей
                next;
            }
        };
    }
    
    # Включаем обратно проверку внешних ключей
    $dbh->do('PRAGMA foreign_keys = ON');
    
    # Выполняем VACUUM для оптимизации базы данных
    $dbh->do('VACUUM');
    
    print "Все таблицы успешно удалены\n";
};

if ($@) {
    warn "Предупреждение при удалении таблиц: $@";
}

$dbh->disconnect; 