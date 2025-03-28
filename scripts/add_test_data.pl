#!/usr/bin/perl
use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use AppConfig;
use Database;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Cwd 'abs_path';

my $project_root = abs_path(File::Spec->catdir($Bin, ".."));

# Создаем конфигурацию с правильным путем
my $config = AppConfig->new;

# Переопределяем путь к базе данных
$config->{db_path} = File::Spec->catfile($project_root, 'data', 'site.db');

my $db = Database->new($config);

# Инициализируем базу данных (создаем таблицы)
print "Инициализация базы данных...\n";
$db->init();
print "Таблицы созданы\n";

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
        facultiesid => 1, # ФИТ
        name => 'Кафедра программной инженерии',
        short_name => 'ПИ',
        description => 'Разработка программного обеспечения'
    },
    {
        facultiesid => 1, # ФИТ
        name => 'Кафедра информационной безопасности',
        short_name => 'ИБ',
        description => 'Защита информации и кибербезопасность'
    },
    {
        facultiesid => 2, # ФФ
        name => 'Кафедра общей физики',
        short_name => 'ОФ',
        description => 'Базовые физические дисциплины'
    },
    # Добавьте другие кафедры по необходимости
);

my $department_sth = $dbh->prepare(q{
    INSERT INTO departments (facultiesid, name, short_name, description)
    VALUES (?, ?, ?, ?)
});

foreach my $department (@departments) {
    $department_sth->execute(
        $department->{facultiesid},
        $department->{name},
        $department->{short_name},
        $department->{description}
    );
}

# После добавления departments добавляем специальности
my @specialties = (
    {
        departmentsid => 1, # Кафедра ПИ
        name => 'Программная инженерия',
        code => '09.03.04',
        level_education => 'бакалавриат',
        form_education => 1, # 1 - очная, 2 - заочная
        budget_places => 50,
        paid_places => 25,
        passing_score => 240,
        description => 'Разработка ПО'
    },
    {
        departmentsid => 2, # Кафедра ИБ
        name => 'Информационная безопасность',
        code => '10.03.01',
        level_education => 'бакалавриат',
        form_education => 1,
        budget_places => 25,
        paid_places => 35,
        passing_score => 250,
        description => 'Защита информации'
    }
);

my $specialty_sth = $dbh->prepare(q{
    INSERT INTO specialties (departmentsid, name, code, level_education, 
                           form_education, budget_places, paid_places, 
                           passing_score, description)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
});

foreach my $specialty (@specialties) {
    $specialty_sth->execute(
        $specialty->{departmentsid},
        $specialty->{name},
        $specialty->{code},
        $specialty->{level_education},
        $specialty->{form_education},
        $specialty->{budget_places},
        $specialty->{paid_places},
        $specialty->{passing_score},
        $specialty->{description}
    );
    $specialty->{id} = $dbh->last_insert_id(undef, undef, "specialties", undef);
}

# Правильное формирование пути к файлу
my $pdf_path = File::Spec->catfile($Bin, 'files', 'mathematicstest.pdf');
print "Пытаюсь открыть файл: $pdf_path\n";

# Проверяем существование файла
unless (-e $pdf_path) {
    die "Файл не существует: $pdf_path\n";
}

# Проверяем права на чтение
unless (-r $pdf_path) {
    die "Нет прав на чтение файла: $pdf_path\n";
}

# Выводим информацию о файле
my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size) = stat($pdf_path);
printf "Размер файла: %d байт\n", $size;
printf "Права доступа: %04o\n", $mode & 07777;

# Пробуем открыть файл с обработкой ошибок
my $pdf_content;
eval {
    open(my $fh, '<:raw', $pdf_path) or die "Ошибка открытия файла: $!";
    local $/;
    $pdf_content = <$fh>;
    close($fh);
};
if ($@) {
    die "Не удалось прочитать файл: $@";
}

print "Файл успешно прочитан\n";

# Добавляем варианты экзаменов
my @exam_variants = (
    # Добавляем PDF файл как вариант для каждой специальности
    {
        specialtiesid => 1,
        task => $pdf_content
    },
    {
        specialtiesid => 1,
        task => $pdf_content  # Второй вариант для первой специальности
    },
    {
        specialtiesid => 2,
        task => $pdf_content
    },
    {
        specialtiesid => 2,
        task => $pdf_content  # Второй вариант для второй специальности
    }
);

my $exam_sth = $dbh->prepare(q{
    INSERT INTO exam_variants (specialtiesid, task)
    VALUES (?, ?)
});

foreach my $exam (@exam_variants) {
    $exam_sth->execute(
        $exam->{specialtiesid},
        $exam->{task}
    );
}

# Добавляем абитуриентов
my @applicants = (
    {
        name => 'Иван',
        surname => 'Иванов',
        patronymic => 'Иванович',
        birth_date => '2006-05-15',
        email => 'ivan@example.com',
        phone_number => '+79001234567',
        series_number_passport => '4520123457'
    },
    {
        name => 'Мария',
        surname => 'Петрова',
        patronymic => 'Александровна',
        birth_date => '2006-08-20',
        email => 'maria@example.com',
        phone_number => '+79009876543',
        series_number_passport => '4520654322'
    }
);

my $applicant_sth = $dbh->prepare(q{
    INSERT INTO applicant (name, surname, patronymic, birth_date, 
                         email, phone_number, series_number_passport)
    VALUES (?, ?, ?, ?, ?, ?, ?)
});

foreach my $applicant (@applicants) {
    $applicant_sth->execute(
        $applicant->{name},
        $applicant->{surname},
        $applicant->{patronymic},
        $applicant->{birth_date},
        $applicant->{email},
        $applicant->{phone_number},
        $applicant->{series_number_passport}
    );
    $applicant->{id} = $dbh->last_insert_id(undef, undef, "applicant", undef);
}

# Модифицируем массив заявлений, добавляя больше тестовых данных
my @applications = (
    {
        specialtiesid => 1,
        applicantid => 1,
        creation_time => '2024-03-17 10:00:00',
        status => 'зачислен',  # Этот абитуриент поступил
        update_time => '2024-03-17 10:00:00'
    },
    {
        specialtiesid => 1,  # Та же специальность
        applicantid => 2,
        creation_time => '2024-03-17 11:00:00',
        status => 'на рассмотрении',  # Этот еще нет
        update_time => '2024-03-17 12:00:00'
    }
);

my $application_sth = $dbh->prepare(q{
    INSERT INTO application (specialtiesid, applicantid, creation_time, 
                           status, update_time)
    VALUES (?, ?, ?, ?, ?)
});

foreach my $application (@applications) {
    $application_sth->execute(
        $application->{specialtiesid},
        $application->{applicantid},
        $application->{creation_time},
        $application->{status},
        $application->{update_time}
    );
}

$dbh->disconnect;
print "Тестовые данные успешно добавлены\n"; 