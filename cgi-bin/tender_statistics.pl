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
use JSON;

my $cgi = CGI->new;
my $config = AppConfig->new;
my $project_root = File::Spec->catdir($Bin, '..');
$config->{db_path} = File::Spec->catfile($project_root, 'data', 'site.db');
my $db = Database->new($config);
my $dbh = $db->connect;

# AJAX-обработчики
if ($cgi->param('action')) {
    my $action = $cgi->param('action');
    
    if ($action eq 'get_departments') {
        my $faculty_id = $cgi->param('faculty_id');
        my $sth = $dbh->prepare(q{
            SELECT id, name FROM departments 
            WHERE facultiesid = ? 
            ORDER BY name
        });
        $sth->execute($faculty_id);
        my $departments = $sth->fetchall_arrayref({});
        print $cgi->header(-type => 'application/json', -charset => 'utf-8');
        print JSON->new->encode($departments);
        exit;
    }
    
    elsif ($action eq 'get_specialties') {
        my $department_id = $cgi->param('department_id');
        my $sth = $dbh->prepare(q{
            SELECT id, name FROM specialties 
            WHERE departmentsid = ? 
            ORDER BY name
        });
        $sth->execute($department_id);
        my $specialties = $sth->fetchall_arrayref({});
        print $cgi->header(-type => 'application/json', -charset => 'utf-8');
        print JSON->new->encode($specialties);
        exit;
    }
    
    elsif ($action eq 'get_statistics') {
        my @specialty_ids = split(',', $cgi->param('specialty_ids'));
        my $placeholders = join(',', ('?') x @specialty_ids);
        
        my $sth = $dbh->prepare(qq{
            SELECT ts.*, s.name as specialty_name, d.name as department_name, f.name as faculty_name
            FROM tender_statistics ts
            JOIN specialties s ON ts.specialtiesid = s.id
            JOIN departments d ON s.departmentsid = d.id
            JOIN faculties f ON d.facultiesid = f.id
            WHERE ts.specialtiesid IN ($placeholders)
            ORDER BY ts.year DESC, f.name, d.name, s.name
        });
        $sth->execute(@specialty_ids);
        my $statistics = $sth->fetchall_arrayref({});
        print $cgi->header(-type => 'application/json', -charset => 'utf-8');
        print JSON->new->encode($statistics);
        exit;
    }
}

# Получаем список факультетов для начального отображения
my $faculties_sth = $dbh->prepare('SELECT id, name FROM faculties ORDER BY name');
$faculties_sth->execute;
my $faculties = $faculties_sth->fetchall_arrayref({});

# Формируем HTML страницу
print $cgi->header(-charset => 'UTF-8');
print <<HTML;
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Статистика конкурсного отбора</title>
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
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

        .selection-form {
            background-color: #f8f9fa;
            padding: 2rem;
            border-radius: 8px;
            border-left: 4px solid #003366;
            margin-bottom: 2rem;
        }

        .form-group {
            margin-bottom: 1rem;
        }

        select, button {
            width: 100%;
            padding: 0.5rem;
            margin-top: 0.5rem;
            border: 1px solid #ddd;
            border-radius: 4px;
            font-size: 1rem;
        }

        button {
            background-color: #003366;
            color: white;
            border: none;
            padding: 1rem;
            cursor: pointer;
            transition: background-color 0.3s;
        }

        button:hover {
            background-color: #004d99;
        }

        .statistics-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 2rem;
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

        .footer {
            background-color: #003366;
            color: white;
            text-align: center;
            padding: 1rem;
            margin-top: 2rem;
        }
    </style>
</head>
<body>
    <header class="header">
        <h1>Статистика конкурсного отбора</h1>
        <p>Выберите интересующие вас направления подготовки</p>
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
        <div class="selection-form">
            <div class="form-group">
                <label for="faculty">Факультет:</label>
                <select id="faculty">
                    <option value="">Выберите факультет</option>
HTML

foreach my $faculty (@$faculties) {
    print qq{<option value="$faculty->{id}">$faculty->{name}</option>};
}

print <<HTML;
                </select>
            </div>
            <div class="form-group">
                <label for="department">Кафедра:</label>
                <select id="department" disabled>
                    <option value="">Сначала выберите факультет</option>
                </select>
            </div>
            <div class="form-group">
                <label for="specialties">Специальности:</label>
                <select id="specialties" multiple disabled>
                    <option value="">Сначала выберите кафедру</option>
                </select>
            </div>
            <button id="show-statistics" disabled>Показать статистику</button>
        </div>
        <div id="statistics-results"></div>
    </div>

    <footer class="footer">
        <p>&copy; 2025 Университет. Все права защищены.</p>
        <p>Лицензия на осуществление образовательной деятельности № XXX от XX.XX.XXXX</p>
    </footer>

    <script>
    jQuery(document).ready(function(\$) {
        \$('#faculty').change(function() {
            var facultyId = \$(this).val();
            var \$departmentSelect = \$('#department');
            var \$specialtiesSelect = \$('#specialties');
            var \$showStatisticsBtn = \$('#show-statistics');
            
            if (facultyId) {
                \$.ajax({
                    url: '/cgi-bin/tender_statistics.pl',
                    method: 'GET',
                    data: {
                        action: 'get_departments',
                        faculty_id: facultyId
                    },
                    success: function(departments) {
                        \$departmentSelect.html('<option value="">Выберите кафедру</option>');
                        departments.forEach(function(dept) {
                            \$departmentSelect.append(
                                \$('<option></option>').val(dept.id).text(dept.name)
                            );
                        });
                        \$departmentSelect.prop('disabled', false);
                        \$specialtiesSelect.prop('disabled', true);
                        \$showStatisticsBtn.prop('disabled', true);
                    }
                });
            } else {
                \$departmentSelect.prop('disabled', true);
                \$specialtiesSelect.prop('disabled', true);
                \$showStatisticsBtn.prop('disabled', true);
            }
        });

        \$('#department').change(function() {
            var departmentId = \$(this).val();
            var \$specialtiesSelect = \$('#specialties');
            var \$showStatisticsBtn = \$('#show-statistics');
            
            if (departmentId) {
                \$.ajax({
                    url: '/cgi-bin/tender_statistics.pl',
                    method: 'GET',
                    data: {
                        action: 'get_specialties',
                        department_id: departmentId
                    },
                    success: function(specialties) {
                        \$specialtiesSelect.html('');
                        specialties.forEach(function(spec) {
                            \$specialtiesSelect.append(
                                \$('<option></option>').val(spec.id).text(spec.name)
                            );
                        });
                        \$specialtiesSelect.prop('disabled', false);
                        \$showStatisticsBtn.prop('disabled', false);
                    }
                });
            } else {
                \$specialtiesSelect.prop('disabled', true);
                \$showStatisticsBtn.prop('disabled', true);
            }
        });

        \$('#show-statistics').click(function() {
            var selectedSpecialties = \$('#specialties').val();
            if (selectedSpecialties && selectedSpecialties.length > 0) {
                \$.ajax({
                    url: '/cgi-bin/tender_statistics.pl',
                    method: 'GET',
                    data: {
                        action: 'get_statistics',
                        specialty_ids: selectedSpecialties.join(',')
                    },
                    success: function(statistics) {
                        var html = '<table class="statistics-table">' +
                            '<thead><tr>' +
                            '<th>Год</th>' +
                            '<th>Факультет</th>' +
                            '<th>Кафедра</th>' +
                            '<th>Специальность</th>' +
                            '<th>Количество мест</th>' +
                            '<th>Подано заявлений</th>' +
                            '<th>Конкурс (чел/место)</th>' +
                            '</tr></thead><tbody>';
                        
                        statistics.forEach(function(stat) {
                            var competition = (stat.number_application / stat.number_enrollment).toFixed(1);
                            html += '<tr>' +
                                '<td>' + stat.year + '</td>' +
                                '<td>' + stat.faculty_name + '</td>' +
                                '<td>' + stat.department_name + '</td>' +
                                '<td>' + stat.specialty_name + '</td>' +
                                '<td>' + stat.number_enrollment + '</td>' +
                                '<td>' + stat.number_application + '</td>' +
                                '<td>' + competition + '</td>' +
                                '</tr>';
                        });
                        
                        html += '</tbody></table>';
                        \$('#statistics-results').html(html);
                    }
                });
            }
        });
    });
    </script>
</body>
</html>
HTML

$dbh->disconnect; 