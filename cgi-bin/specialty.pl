#!/usr/bin/perl
use strict;
use warnings;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use FindBin qw($Bin);
use lib "$Bin/../lib";
use AppConfig;
use Database;
use utf8;
use open ':std', ':encoding(UTF-8)';
use File::Spec;

my $cgi = CGI->new;
my $config = AppConfig->new;

my $project_root = File::Spec->catdir($Bin, '..');
$config->{db_path} = File::Spec->catfile($project_root, 'data', 'site.db');

my $db = Database->new($config);
my $specialty_id = $cgi->param('id') || die "Specialty ID is required";
my $dbh = $db->connect;

# Получаем информацию о специальности
my $spec_sth = $dbh->prepare(q{
    SELECT s.*, d.name as department_name, f.name as faculty_name
    FROM specialties s
    JOIN departments d ON s.departmentsid = d.id
    JOIN faculties f ON d.facultiesid = f.id
    WHERE s.id = ?
});
$spec_sth->execute($specialty_id);
my $specialty = $spec_sth->fetchrow_hashref;

# Получаем варианты экзаменов
my $variants_sth = $dbh->prepare(q{
    SELECT id
    FROM exam_variants
    WHERE specialtiesid = ?
});
$variants_sth->execute($specialty_id);
my @variants;
while (my $variant = $variants_sth->fetchrow_hashref) {
    push @variants, $variant;
}

# Получаем статистику поступления
my $stats_sth = $dbh->prepare(q{
    SELECT 
        COUNT(*) as total_applications,
        SUM(CASE WHEN status = 'зачислен' THEN 1 ELSE 0 END) as enrolled,
        strftime('%Y', creation_time) as year
    FROM application
    WHERE specialtiesid = ?
    GROUP BY strftime('%Y', creation_time)
    ORDER BY year DESC
});
$stats_sth->execute($specialty_id);
my @statistics;
while (my $stat = $stats_sth->fetchrow_hashref) {
    push @statistics, $stat;
}

# Формируем HTML
print $cgi->header(-charset => 'UTF-8');
print <<HTML;
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$specialty->{name}</title>
    <style>
        body {
            font-family: 'Arial', sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 0;
        }

        .header {
            background-color: #003366;
            color: white;
            padding: 2rem;
            text-align: center;
        }

        .nav {
            background-color: #004d99;
            padding: 1rem;
        }

        .nav ul {
            list-style: none;
            padding: 0;
            margin: 0;
            display: flex;
            justify-content: center;
        }

        .nav li {
            margin: 0 1rem;
        }

        .nav a {
            color: white;
            text-decoration: none;
            padding: 0.5rem 1rem;
            border-radius: 4px;
            transition: background-color 0.3s;
        }

        .nav a:hover {
            background-color: #0066cc;
        }

        .main-content {
            max-width: 1200px;
            margin: 0 auto;
            padding: 2rem;
        }

        .specialty-info {
            background-color: #f8f9fa;
            padding: 2rem;
            margin: 2rem 0;
            border-radius: 8px;
            border-left: 4px solid #003366;
        }

        .places {
            background-color: #f5f5f5;
            padding: 1rem;
            border-radius: 4px;
            margin: 1rem 0;
        }

        .score {
            font-weight: bold;
            color: #003366;
        }

        .footer {
            background-color: #003366;
            color: white;
            text-align: center;
            padding: 1rem;
            margin-top: 2rem;
        }

        h1, h2, h3 {
            color: #003366;
            margin-top: 0;
        }

        .faculty-name {
            color: #666;
            font-size: 1.2em;
            margin-bottom: 1rem;
        }

        .statistics-table {
            width: 100%;
            border-collapse: collapse;
            margin: 1rem 0;
            background-color: #fff;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            border-radius: 8px;
            overflow: hidden;
        }
        
        .statistics-table th,
        .statistics-table td {
            padding: 1rem;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        
        .statistics-table th {
            background-color: #003366;
            color: white;
        }
        
        .statistics-table tr:nth-child(even) {
            background-color: #f8f9fa;
        }
        
        .statistics-table tr:hover {
            background-color: #f0f0f0;
        }
        
        .competition-rate {
            font-weight: bold;
            color: #003366;
        }

        .variant-list {
            list-style: none;
            padding: 0;
            margin: 1rem 0;
        }
        
        .variant-item {
            margin: 0.5rem 0;
            padding: 0.5rem;
            border: 1px solid #eee;
            border-radius: 4px;
            background-color: #f8f9fa;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .download-link {
            display: inline-block;
            padding: 0.5rem 1rem;
            background-color: #003366;
            color: white;
            text-decoration: none;
            border-radius: 4px;
            transition: background-color 0.3s;
            font-size: 0.9em;
        }
        
        .download-link:hover {
            background-color: #004d99;
        }

        .info-label {
            font-weight: bold;
            color: #003366;
            margin-right: 0.5rem;
        }

        .info-value {
            color: #333;
        }

        .info-row {
            margin: 0.5rem 0;
            padding: 0.5rem 0;
            border-bottom: 1px solid #eee;
        }

        .back-link {
            display: inline-block;
            margin: 1rem 0;
            padding: 0.5rem 1rem;
            background-color: #003366;
            color: white;
            text-decoration: none;
            border-radius: 4px;
            transition: background-color 0.3s;
        }

        .back-link:hover {
            background-color: #004d99;
        }
    </style>
</head>
<body>
    <header class="header">
        <h1>$specialty->{name}</h1>
        <p class="faculty-name">$specialty->{faculty_name}</p>
    </header>

    <nav class="nav">
        <ul>
            <li><a href="/">Главная</a></li>
            <li><a href="/cgi-bin/faculties.pl">Факультеты и кафедры</a></li>
            <li><a href="/cgi-bin/tender_statistics.pl">Конкурсный отбор</a></li>
            <li><a href="/#admission">Правила приёма</a></li>
            <li><a href="/#contacts">Контакты</a></li>
        </ul>
    </nav>

    <div class="main-content">
        <a href="/cgi-bin/department.pl?id=$specialty->{departmentsid}" class="back-link">
            ← Вернуться на страницу кафедры
        </a>

        <section class="specialty-info">
            <h2>Информация о направлении подготовки</h2>
            <div class="info-row">
                <span class="info-label">Код специальности:</span>
                <span class="info-value">$specialty->{code}</span>
            </div>
            <div class="info-row">
                <span class="info-label">Кафедра:</span>
                <span class="info-value">$specialty->{department_name}</span>
            </div>
            <div class="info-row">
                <span class="info-label">Уровень образования:</span>
                <span class="info-value">$specialty->{level_education}</span>
            </div>
            <div class="info-row">
                <span class="info-label">Форма обучения:</span>
                <span class="info-value">
                    @{[$specialty->{form_education} == 1 ? 'очная' : 'заочная']}
                </span>
            </div>
            <div class="places">
                <div class="info-row">
                    <span class="info-label">Бюджетных мест:</span>
                    <span class="info-value">$specialty->{budget_places}</span>
                </div>
                <div class="info-row">
                    <span class="info-label">Платных мест:</span>
                    <span class="info-value">$specialty->{paid_places}</span>
                </div>
            </div>
            <div class="info-row">
                <span class="info-label">Проходной балл:</span>
                <span class="info-value score">$specialty->{passing_score}</span>
            </div>
            <p>$specialty->{description}</p>
        </section>

        <section class="exam-variants">
            <h2>Варианты вступительных заданий</h2>
HTML

if (@variants) {
    print "<ul class='variant-list'>\n";
    for my $i (0 .. $#variants) {
        my $num = $i + 1;
        print <<HTML;
            <li class="variant-item">
                <span>Вариант $num</span>
                <a href="/cgi-bin/download.pl?variant_id=$variants[$i]->{id}" 
                   class="download-link">Скачать</a>
            </li>
HTML
    }
    print "</ul>\n";
} else {
    print "<p>Варианты вступительных заданий пока не добавлены.</p>\n";
}

if (@statistics) {
    print <<HTML;
        <section class="statistics">
            <h2>Статистика поступления</h2>
            <table class="statistics-table">
                <tr>
                    <th>Год</th>
                    <th>Подано заявлений</th>
                    <th>Зачислено</th>
                    <th>Конкурс</th>
                </tr>
HTML

    foreach my $stat (@statistics) {
        my $competition = sprintf("%.1f", 
            $stat->{total_applications} / $specialty->{budget_places}
        );
        print <<HTML;
                <tr>
                    <td>$stat->{year}</td>
                    <td>$stat->{total_applications}</td>
                    <td>$stat->{enrolled}</td>
                    <td>$competition</td>
                </tr>
HTML
    }
    print "</table>\n";
}

print <<HTML;
        </section>
    </div>

    <footer class="footer">
        <p>&copy; 2025 Университет. Все права защищены.</p>
    </footer>
</body>
</html>
HTML

$dbh->disconnect; 