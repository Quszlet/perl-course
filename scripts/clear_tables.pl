#!/usr/bin/perl
use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use AppConfig;
use Database;

print "Очистка таблиц базы данных...\n";

my $project_root = File::Spec->catdir($Bin, '..');

# Создаем конфигурацию с правильным путем
my $config = AppConfig->new;

# Переопределяем путь к базе данных
$config->{db_path} = File::Spec->catfile($project_root, 'data', 'site.db');
my $db = Database->new($config);
my $dbh = $db->connect;

eval {
    # Отключаем проверку внешних ключей для удаления
    $dbh->do('PRAGMA foreign_keys = OFF');
    
    # Очищаем таблицы (порядок важен из-за зависимостей)
    $dbh->do('DELETE FROM application');
    $dbh->do('DELETE FROM exam_variants');
    $dbh->do('DELETE FROM tender_statistics');
    $dbh->do('DELETE FROM applicant');
    $dbh->do('DELETE FROM specialties');
    $dbh->do('DELETE FROM departments');
    $dbh->do('DELETE FROM faculties');
    
    # Сбрасываем автоинкремент
    $dbh->do('DELETE FROM sqlite_sequence WHERE name IN 
        ("application", "exam_variants", "tender_statistics", 
         "applicant", "specialties", "departments", "faculties")');
    
    # Включаем обратно проверку внешних ключей
    $dbh->do('PRAGMA foreign_keys = ON');
    
    # Выполняем VACUUM для оптимизации базы данных
    $dbh->do('VACUUM');
    
    print "Таблицы успешно очищены\n";
};

if ($@) {
    die "Ошибка при очистке таблиц: $@";
}

$dbh->disconnect; 