#!/usr/bin/perl
use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use AppConfig;
use Database;
use utf8;
use open ':std', ':encoding(UTF-8)';

my $project_root = File::Spec->catdir($Bin, '..');

# Создаем конфигурацию с правильным путем
my $config = AppConfig->new;

# Переопределяем путь к базе данных
$config->{db_path} = File::Spec->catfile($project_root, 'data', 'site.db');

my $db = Database->new($config);
my $dbh = $db->connect;

# Добавляем факультеты
my @faculties = (
    {
        name => 'Факультет информационных технологий',
        short_name => 'ФИТ',
        description => 'Подготовка специалистов в области IT'
    },
    {
        name => 'Физический факультет',
        short_name => 'ФФ',
        description => 'Изучение фундаментальных законов природы'
    },
    # Добавьте другие факультеты по необходимости
);

my $faculty_sth = $dbh->prepare(q{
    INSERT INTO faculties (name, short_name, description)
    VALUES (?, ?, ?)
});

foreach my $faculty (@faculties) {
    $faculty_sth->execute(
        $faculty->{name},
        $faculty->{short_name},
        $faculty->{description}
    );
    $faculty->{id} = $dbh->last_insert_id(undef, undef, "faculties", undef);
}

# Добавляем кафедры
my @departments = (
    {
        faculty_id => 1, # ФИТ
        name => 'Кафедра программной инженерии',
        short_name => 'ПИ',
        description => 'Разработка программного обеспечения'
    },
    {
        faculty_id => 1, # ФИТ
        name => 'Кафедра информационной безопасности',
        short_name => 'ИБ',
        description => 'Защита информации и кибербезопасность'
    },
    {
        faculty_id => 2, # ФФ
        name => 'Кафедра общей физики',
        short_name => 'ОФ',
        description => 'Базовые физические дисциплины'
    },
    # Добавьте другие кафедры по необходимости
);

my $department_sth = $dbh->prepare(q{
    INSERT INTO departments (faculty_id, name, short_name, description)
    VALUES (?, ?, ?, ?)
});

foreach my $department (@departments) {
    $department_sth->execute(
        $department->{faculty_id},
        $department->{name},
        $department->{short_name},
        $department->{description}
    );
}

$dbh->disconnect;
print "Тестовые данные успешно добавлены\n"; 