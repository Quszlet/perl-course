package RequestHandler;
use strict;
use warnings;
use HTTP::Status;
use HTTP::Response;
use File::Spec;

sub new {
    my ($class, $config) = @_;
    my $self = {
        config => $config,
    };
    return bless $self, $class;
}

sub handle_request {
    my ($self, $client) = @_;
    
    while (my $request = $client->get_request) {
        print "Получен запрос: ", $request->method, " ", $request->uri->path, "\n";
        
        my $path = $request->uri->path;
        $path = '/index.html' if $path eq '/';
        
        my $response;
        if ($path =~ m{^/cgi-bin/(.+)}) {
            $response = $self->handle_cgi_request($client, $request, $1);
        } else {
            $response = $self->serve_static_file($client, $path);
        }
        
        # Отправляем ответ клиенту
        $client->send_response($response);
    }
}

sub handle_cgi_request {
    my ($self, $client, $request, $script_name) = @_;
    
    my $script_path = File::Spec->catfile($self->{config}->get('cgi_bin'), $script_name);
    
    if (-f $script_path && -x $script_path) {
        local %ENV = (
            %ENV,
            'SCRIPT_NAME' => "/cgi-bin/$script_name",
            'REQUEST_METHOD' => $request->method,
            'QUERY_STRING' => $request->uri->query || '',
            'CONTENT_TYPE' => $request->header('Content-Type') || '',
            'CONTENT_LENGTH' => $request->header('Content-Length') || 0,
            'REMOTE_ADDR' => $client->peerhost || '127.0.0.1',
            'SERVER_PROTOCOL' => 'HTTP/1.1',
            'SERVER_PORT' => $self->{config}->get('port'),
            'DB_PATH' => $self->{config}->get('db_path'),
            'LANG' => 'ru_RU.UTF-8',
            'LC_ALL' => 'ru_RU.UTF-8',
        );

        my $output = '';
        {
            open(my $pipe, '-|', $script_path) or die "Не удалось запустить CGI скрипт: $!";
            local $/;
            $output = <$pipe>;
            close($pipe);
        }

        if ($output) {
            my ($headers_text, $body) = split /\r?\n\r?\n/, $output, 2;
            
            # Если нет разделителя заголовков и тела
            if (!$body) {
                $body = $headers_text;
                return HTTP::Response->new(
                    RC_OK,
                    "OK",
                    ['Content-Type' => 'text/html'],
                    $body
                );
            }
            
            # Парсим заголовки
            my @headers;
            foreach my $header (split /\r?\n/, $headers_text) {
                if ($header =~ /^([^:]+):\s*(.+)$/) {
                    push @headers, $1 => $2;
                }
            }

            return HTTP::Response->new(
                RC_OK,
                "OK",
                \@headers,
                $body
            );
        } else {
            return HTTP::Response->new(
                RC_OK,
                "OK",
                ['Content-Type' => 'text/html'],
                "Скрипт выполнен, но не вернул данных"
            );
        }
    } else {
        return HTTP::Response->new(
            RC_NOT_FOUND,
            "Not Found",
            ['Content-Type' => 'text/plain'],
            "CGI скрипт не найден или не исполняемый: $script_path"
        );
    }
}

sub serve_static_file {
    my ($self, $client, $path) = @_;
    
    # Если путь корневой, отдаем index.html
    $path = '/index.html' if $path eq '/';
    
    # Удаляем начальный слеш и любые попытки перейти в родительские директории
    $path =~ s{^/}{};
    $path =~ s{\.\.}{}g;
    
    my $file_path = File::Spec->catfile($self->{config}->get('document_root'), $path);
    print "Serving file: $file_path\n";  # Отладочная информация
    
    if (-f $file_path) {
        if (open my $fh, '<:raw', $file_path) {
            local $/;
            my $content = <$fh>;
            close $fh;
            
            my $mime_type = 'text/plain';
            if ($file_path =~ /\.(\w+)$/) {
                my $ext = lc($1);
                $mime_type = $self->{config}->get('mime_types')->{$ext} 
                    if exists $self->{config}->get('mime_types')->{$ext};
            }
            
            return HTTP::Response->new(
                RC_OK,
                "OK",
                [
                    'Content-Type' => $mime_type,
                    'Content-Length' => length($content)
                ],
                $content
            );
        } else {
            return HTTP::Response->new(
                RC_FORBIDDEN,
                "Forbidden",
                ['Content-Type' => 'text/plain'],
                "Нет доступа к файлу"
            );
        }
    } else {
        return HTTP::Response->new(
            RC_NOT_FOUND,
            "Not Found",
            ['Content-Type' => 'text/plain'],
            "Файл не найден: $file_path"
        );
    }
}

1; 