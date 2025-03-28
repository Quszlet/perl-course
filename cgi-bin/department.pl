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



# Создаем объекты CGI и конфигурации
my $cgi = CGI->new;
my $config = AppConfig->new;

my $project_root = File::Spec->catdir($Bin, '..');  # Поднимаемся только на один уровень
$config->{db_path} = File::Spec->catfile($project_root, 'data', 'site.db');

my $db = Database->new($config);

my $department_id = $cgi->param('id') || die "Department ID is required";

my $dbh = $db->connect;


my $dept_sth = $dbh->prepare(q{
    SELECT d.*, f.name as faculty_name 
    FROM departments d
    JOIN faculties f ON d.facultiesid = f.id
    WHERE d.id = ?
});
$dept_sth->execute($department_id);
my $department = $dept_sth->fetchrow_hashref;


my $spec_sth = $dbh->prepare(q{
    SELECT * FROM specialties 
    WHERE departmentsid = ?
    ORDER BY name
});
$spec_sth->execute($department_id);
my @specialties;
while (my $spec = $spec_sth->fetchrow_hashref) {
    push @specialties, $spec;
}

# Получаем статистику конкурсного отбора для всех специальностей кафедры
my $stats_sth = $dbh->prepare(q{
    SELECT ts.*, s.name as specialty_name
    FROM tender_statistics ts
    JOIN specialties s ON ts.specialtiesid = s.id
    WHERE s.departmentsid = ?
    ORDER BY ts.year DESC, s.name
});
$stats_sth->execute($department_id);
my @statistics;
while (my $stat = $stats_sth->fetchrow_hashref) {
    push @statistics, $stat;
}

my $variants_sth = $dbh->prepare(q{
    SELECT s.id as specialty_id, s.name as specialty_name,
           GROUP_CONCAT(ev.id) as variant_ids,
           GROUP_CONCAT(ev.task) as tasks,
           COUNT(ev.id) as variant_count
    FROM specialties s
    LEFT JOIN exam_variants ev ON ev.specialtiesid = s.id
    WHERE s.departmentsid = ?
    GROUP BY s.id, s.name
    ORDER BY s.name
});
$variants_sth->execute($department_id);
my @variants_by_specialty;
while (my $row = $variants_sth->fetchrow_hashref) {
    push @variants_by_specialty, $row;
}

# Формируем HTML
print $cgi->header(-charset => 'UTF-8');
print <<HTML;
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$department->{name}</title>
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

        .department-info {
            background-color: #f8f9fa;
            padding: 2rem;
            margin: 2rem 0;
            border-radius: 8px;
            border-left: 4px solid #003366;
        }

        .specialties-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 2rem;
            margin-top: 2rem;
        }

        .specialty-card {
            border: 1px solid #ddd;
            padding: 1.5rem;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            background-color: #fff;
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

        .specialty-link {
            display: block;
            padding: 1rem;
            margin: 0.5rem 0;
            background-color: #f8f9fa;
            border: 1px solid #ddd;
            border-radius: 8px;
            text-decoration: none;
            color: #003366;
            transition: all 0.3s;
        }
        
        .specialty-link:hover {
            background-color: #e9ecef;
            transform: translateX(10px);
        }
        
        .specialty-code {
            color: #666;
            font-size: 0.9em;
        }
    </style>
</head>
<body>
    <header class="header">
        <h1>$department->{name}</h1>
        <p class="faculty-name">Факультет: $department->{faculty_name}</p>
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
        <section class="department-info">
            <h2>О кафедре</h2>
            <p>$department->{description}</p>
        </section>

        <section class="specialties">
            <h2>Направления подготовки</h2>
HTML

if (@specialties) {
    foreach my $spec (@specialties) {
        print <<SPECIALTY;
            <a href="/cgi-bin/specialty.pl?id=$spec->{id}" class="specialty-link">
                <h3>$spec->{name}</h3>
                <span class="specialty-code">Код специальности: $spec->{code}</span>
            </a>
SPECIALTY
    }
} else {
    print '<p>На данный момент информация о направлениях подготовки отсутствует.</p>';
}

if (@statistics) {
    print <<HTML;
        <section class="statistics">
            <h2>Статистика конкурсного отбора</h2>
            <table class="statistics-table">
                <thead>
                    <tr>
                        <th>Год</th>
                        <th>Специальность</th>
                        <th>Количество мест</th>
                        <th>Подано заявлений</th>
                        <th>Конкурс (чел/место)</th>
                    </tr>
                </thead>
                <tbody>
HTML

    foreach my $stat (@statistics) {
        my $competition = sprintf("%.1f", 
            $stat->{number_application} / $stat->{number_enrollment}
        );
        print <<HTML;
                    <tr>
                        <td>$stat->{year}</td>
                        <td>$stat->{specialty_name}</td>
                        <td>$stat->{number_enrollment}</td>
                        <td>$stat->{number_application}</td>
                        <td class="competition-rate">$competition</td>
                    </tr>
HTML
    }

    print <<HTML;
                </tbody>
            </table>
        </section>
HTML
}

if (@variants_by_specialty) {
    print <<HTML;
        <section class="exam-variants">
            <h2>Варианты вступительных заданий</h2>
            <style>
                .variants-grid {
                    display: grid;
                    grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
                    gap: 2rem;
                    margin-top: 2rem;
                }
                
                .variant-card {
                    border: 1px solid #ddd;
                    padding: 1.5rem;
                    border-radius: 8px;
                    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
                    background-color: #fff;
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
                
                .file-info {
                    display: flex;
                    align-items: center;
                    margin-right: 1rem;
                    color: #666;
                }
                
                .file-icon {
                    margin-right: 0.5rem;
                    font-size: 1.2em;
                }
                
                .variant-header {
                    display: flex;
                    justify-content: space-between;
                    align-items: center;
                    margin-bottom: 1rem;
                }
                
                .variant-count {
                    background-color: #003366;
                    color: white;
                    padding: 0.25rem 0.75rem;
                    border-radius: 1rem;
                    font-size: 0.9em;
                }
            </style>
            <div class="variants-grid">
HTML

    foreach my $specialty (@variants_by_specialty) {
        next unless $specialty->{variant_count} > 0;
        
        my @variant_ids = split(',', $specialty->{variant_ids});
        
        print <<HTML;
                <div class="variant-card">
                    <div class="variant-header">
                        <h3>$specialty->{specialty_name}</h3>
                        <span class="variant-count">$specialty->{variant_count} вариант(ов)</span>
                    </div>
                    <ul class="variant-list">
HTML

        for my $i (0 .. $#variant_ids) {
            my $variant_num = $i + 1;
            print <<HTML;
                        <li class="variant-item">
                            <div style="display: flex; justify-content: space-between; align-items: center;">
                                <span>Вариант $variant_num</span>
                                <a href="/cgi-bin/download.pl?variant_id=$variant_ids[$i]" class="download-link">
                                    Скачать
                                </a>
                            </div>
                        </li>
HTML
        }

        print <<HTML;
                    </ul>
                </div>
HTML
    }

    print <<HTML;
            </div>
        </section>
HTML
}

print <<HTML;
        </section>
    </div>

    <footer class="footer">
        <p>&copy; 2025 Университет. Все права защищены.</p>
        <p>Лицензия на осуществление образовательной деятельности № XXX от XX.XX.XXXX</p>
    </footer>
</body>
</html>
HTML

$dbh->disconnect;

