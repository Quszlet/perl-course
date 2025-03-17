package AppConfig;
use strict;
use warnings;
use FindBin qw($Bin);

sub new {
    my ($class) = @_;
    my $self = {
        port => '8081',
        document_root => "$Bin/public",
        cgi_bin => "$Bin/cgi-bin",
        db_path => "$Bin/data/site.db",
        mime_types => {
            'html' => 'text/html',
            'css'  => 'text/css',
            'js'   => 'application/javascript',
            'jpg'  => 'image/jpeg',
            'jpeg' => 'image/jpeg',
            'png'  => 'image/png',
            'gif'  => 'image/gif',
            'txt'  => 'text/plain',
        }
    };
    return bless $self, $class;
}

sub get {
    my ($self, $key) = @_;
    return $self->{$key};
}

1; 