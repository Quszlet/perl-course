package Database;
use strict;
use warnings;
use DBI;
use File::Path qw(make_path);
use File::Spec;

sub new {
    my ($class, $config) = @_;
    my $self = {
        db_path => $config->get('db_path'),
    };
    return bless $self, $class;
}

sub init {
    my ($self) = @_;
    
    # Создаем директорию для базы данных
    my $db_dir = File::Spec->catpath((File::Spec->splitpath($self->{db_path}))[0, 1], '');
    make_path($db_dir) unless -d $db_dir;
    
    my $dbh = $self->connect;
    
    $dbh->do(q{
        CREATE TABLE IF NOT EXISTS faculties (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name VARCHAR(50) NOT NULL UNIQUE,
            short_name VARCHAR(15) NOT NULL,
            description VARCHAR(255)
        )
    });
    
    $dbh->do(q{
        CREATE TABLE IF NOT EXISTS departments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name VARCHAR(50) NOT NULL,
            short_name VARCHAR(15) NOT NULL,
            description VARCHAR(255),
            facultiesid INTEGER(10) NOT NULL,
            FOREIGN KEY (facultiesid) REFERENCES faculties(id)
        )
    });
    
    $dbh->do(q{
        CREATE TABLE IF NOT EXISTS specialties (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            departmentsid INTEGER(10) NOT NULL,
            name VARCHAR(50) NOT NULL,
            code VARCHAR(20) NOT NULL,
            level_education VARCHAR(15) NOT NULL,
            form_education INTEGER(10) NOT NULL,
            budget_places INTEGER(4),
            paid_places INTEGER(10),
            passing_score INTEGER(3),
            description INTEGER(10),
            FOREIGN KEY (departmentsid) REFERENCES departments(id)
        )
    });
    
    $dbh->do(q{
        CREATE TABLE IF NOT EXISTS exam_variants (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            task BLOB NOT NULL,
            specialtiesid INTEGER(10) NOT NULL,
            FOREIGN KEY (specialtiesid) REFERENCES specialties(id)
        )
    });
    
    $dbh->do(q{
        CREATE TABLE IF NOT EXISTS applicant (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name VARCHAR(50) NOT NULL,
            surname VARCHAR(50) NOT NULL,
            patronymic VARCHAR(50),
            birth_date TIMESTAMP NOT NULL,
            email VARCHAR(60) UNIQUE NOT NULL,
            phone_number VARCHAR(12) UNIQUE NOT NULL,
            series_number_passport VARCHAR(15) UNIQUE NOT NULL
        )
    });
    
    $dbh->do(q{
        CREATE TABLE IF NOT EXISTS application (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            specialtiesid INTEGER(10) NOT NULL,
            applicantid INTEGER(10) NOT NULL,
            creation_time TIMESTAMP NOT NULL,
            status VARCHAR(40) NOT NULL, 
            update_time INTEGER(10) NOT NULL,
            FOREIGN KEY (specialtiesid) REFERENCES specialties(id),
            FOREIGN KEY (applicantid) REFERENCES applicant(id)
        )
    });
    
    $dbh->disconnect;
}

sub connect {
    my ($self) = @_;
    return DBI->connect(
        "dbi:SQLite:dbname=$self->{db_path}", 
        "", 
        "", 
        {
            RaiseError => 1,
            AutoCommit => 1,
            sqlite_unicode => 1,  # Включаем поддержку UTF-8
        }
    );
}

1;