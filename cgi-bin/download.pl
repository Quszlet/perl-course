#!/usr/bin/perl
use strict;
use warnings;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use FindBin qw($Bin);
use lib "$Bin/../lib";
use AppConfig;
use Database;
use MIME::Base64;
use File::Basename;

my $cgi = CGI->new;
my $config = AppConfig->new;
my $project_root = File::Spec->catdir($Bin, '..');
$config->{db_path} = File::Spec->catfile($project_root, 'data', 'site.db');

my $db = Database->new($config);
my $dbh = $db->connect;

my $variant_id = $cgi->param('variant_id') || die "Variant ID is required";

# Получаем файл из базы данных
my $sth = $dbh->prepare(q{
    SELECT ev.task, ev.id, s.name as specialty_name
    FROM exam_variants ev
    JOIN specialties s ON ev.specialtiesid = s.id
    WHERE ev.id = ?
});
$sth->execute($variant_id);
my $variant = $sth->fetchrow_hashref;

if ($variant) {
    # Определяем тип файла
    my $content_type = 'application/octet-stream';
    my $extension = '';
    
    if ($variant->{task} =~ /^%PDF/) {
        $content_type = 'application/pdf';
        $extension = '.pdf';
    } elsif ($variant->{task} =~ /^PK/) {
        $content_type = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
        $extension = '.docx';
    } elsif ($variant->{task} =~ /^\xD0\xCF/) {
        $content_type = 'application/msword';
        $extension = '.doc';
    }

    # Формируем имя файла
    my $filename = "variant_" . $variant->{id} . "_" . 
                  $variant->{specialty_name} . $extension;
    $filename =~ s/\s+/_/g; # Заменяем пробелы на подчеркивания

    # Отправляем файл
    print $cgi->header(
        -type => $content_type,
        -attachment => $filename,
        -charset => 'utf-8'
    );
    print $variant->{task};
} else {
    print $cgi->header(-status => '404 Not Found');
    print "File not found";
}

$dbh->disconnect; 