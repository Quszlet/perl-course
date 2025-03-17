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
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE NOT NULL,
            password TEXT NOT NULL,
            email TEXT UNIQUE NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    });
    
    $dbh->do(q{
        CREATE TABLE IF NOT EXISTS pages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            slug TEXT UNIQUE NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    });
    
    $dbh->do(q{
        CREATE TABLE IF NOT EXISTS faculties (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            short_name TEXT NOT NULL,
            description TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    });
    
    $dbh->do(q{
        CREATE TABLE IF NOT EXISTS departments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            faculty_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            short_name TEXT NOT NULL,
            description TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (faculty_id) REFERENCES faculties(id)
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