#!/usr/bin/perl
use strict;
use warnings;
use CGI;
use DBI;
use JSON;
use FindBin qw($Bin);
use File::Spec;
use lib "$Bin/../lib";
use Database;
use AppConfig;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Encode qw(decode encode);

# Определяем корневую директорию проекта
my $project_root = File::Spec->catdir($Bin, '..');

# Создаем конфигурацию с правильным путем
my $config = AppConfig->new;

# Переопределяем путь к базе данных
$config->{db_path} = File::Spec->catfile($project_root, 'data', 'site.db');

my $cgi = CGI->new;
my $db = Database->new($config);
my $dbh = $db->connect;

# Устанавливаем UTF-8 для базы данных
$dbh->{sqlite_unicode} = 1;

# Проверяем, является ли это AJAX-запросом для получения кафедр
if ($cgi->param('action') && $cgi->param('action') eq 'get_departments') {
    my $faculty_id = $cgi->param('faculty_id');
    my $departments = get_departments($dbh, $faculty_id);
    
    # Явно декодируем все строки из UTF-8
    for my $dept (@$departments) {
        $dept->{name} = decode('UTF-8', $dept->{name}) unless utf8::is_utf8($dept->{name});
        $dept->{description} = decode('UTF-8', $dept->{description}) if $dept->{description} && !utf8::is_utf8($dept->{description});
    }
    
    my $json = JSON->new->utf8->encode($departments);
    
    print $cgi->header(
        -type => 'application/json',
        -charset => 'utf-8',
        -access_control_allow_origin => '*'
    );
    print $json;
    exit;
}

# Получаем список всех факультетов
my $faculties = get_faculties($dbh);

# Формируем HTML-страницу
print $cgi->header(-type => 'text/html', -charset => 'utf-8');
print <<HTML;
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Факультеты и кафедры</title>
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

        .faculty {
            margin: 2rem 0;
            padding: 1.5rem;
            border: 1px solid #ddd;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }

        .faculty-header {
            cursor: pointer;
            padding: 1rem;
            background-color: #f8f9fa;
            border-radius: 4px;
            transition: background-color 0.3s;
        }

        .faculty-header:hover {
            background-color: #e9ecef;
        }

        .departments {
            display: none;
            margin-top: 1rem;
            padding-left: 2rem;
            border-left: 4px solid #003366;
        }

        .department {
            margin: 1rem 0;
            padding: 1rem;
            background-color: #fff;
            border-radius: 4px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
        }

        .footer {
            background-color: #003366;
            color: white;
            text-align: center;
            padding: 1rem;
            margin-top: 2rem;
        }

        h1, h2, h3, h4 {
            color: #003366;
            margin-top: 0;
        }

        .department h4 {
            color: #004d99;
            margin-bottom: 0.5rem;
        }

        .department p {
            margin: 0;
            color: #666;
        }
    </style>
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
    <script>
    \$(document).ready(function() {
        \$('.faculty-header').click(function() {
            const facultyId = \$(this).data('faculty-id');
            const departmentsDiv = \$('#departments-' + facultyId);
            
            if (departmentsDiv.is(':empty')) {
                \$.ajax({
                    url: '/cgi-bin/faculties.pl',
                    data: {
                        action: 'get_departments',
                        faculty_id: facultyId
                    },
                    dataType: 'json',
                    contentType: 'application/json; charset=utf-8',
                    success: function(departments) {
                        let html = '<div class="departments-list">';
                        departments.forEach(function(dept) {
                            // Декодируем строки из UTF-8
                            const name = decodeURIComponent(escape(dept.name));
                            const description = dept.description ? decodeURIComponent(escape(dept.description)) : '';
                            
                            html += '<div class="department">';
                            html += '<h4>' + name + '</h4>';
                            if (description) {
                                html += '<p>' + description + '</p>';
                            }
                            html += '</div>';
                        });
                        html += '</div>';
                        departmentsDiv.html(html).slideDown();
                    },
                    error: function(xhr, status, error) {
                        console.error('Error:', error);
                        console.log('Response:', xhr.responseText);
                    }
                });
            } else {
                departmentsDiv.slideToggle();
            }
        });
    });
    </script>
</head>
<body>
    <header class="header">
        <h1>Факультеты и кафедры</h1>
        <p>Выберите интересующий вас факультет для просмотра кафедр</p>
    </header>

    <nav class="nav">
        <ul>
            <li><a href="/">Главная</a></li>
            <li><a href="/cgi-bin/faculties.pl">Факультеты и кафедры</a></li>
            <li><a href="/#programs">Программы обучения</a></li>
            <li><a href="/#admission">Правила приёма</a></li>
            <li><a href="/#contacts">Контакты</a></li>
        </ul>
    </nav>

    <div class="main-content">
HTML

foreach my $faculty (@$faculties) {
    print <<HTML;
        <div class="faculty">
            <div class="faculty-header" data-faculty-id="$faculty->{id}">
                <h2>$faculty->{name}</h2>
                <p>$faculty->{description}</p>
            </div>
            <div id="departments-$faculty->{id}" class="departments"></div>
        </div>
HTML
}

print <<HTML;
    </div>

    <footer class="footer">
        <p>&copy; 2024 Университет. Все права защищены.</p>
        <p>Лицензия на осуществление образовательной деятельности № XXX от XX.XX.XXXX</p>
    </footer>
</body>
</html>
HTML

$dbh->disconnect;

# Вспомогательные функции
sub get_faculties {
    my ($dbh) = @_;
    my $sth = $dbh->prepare(q{
        SELECT id, name, short_name, description
        FROM faculties
        ORDER BY name
    });
    $sth->execute;
    return $sth->fetchall_arrayref({});
}

sub get_departments {
    my ($dbh, $faculty_id) = @_;
    my $sth = $dbh->prepare(q{
        SELECT id, name, short_name, description
        FROM departments
        WHERE faculty_id = ?
        ORDER BY name
    });
    $sth->execute($faculty_id);
    return $sth->fetchall_arrayref({});
} 