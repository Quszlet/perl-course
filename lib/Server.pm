package Server;
use strict;
use warnings;
use HTTP::Daemon;
use POSIX ":sys_wait_h"; # Для WNOHANG

# Глобальная переменная для хранения серверного сокета
my $daemon;
my $running = 1;  # Флаг для контроля работы сервера

# Обработчик сигнала прерывания
sub signal_handler {
    my $signal = shift;
    print "\nПолучен сигнал $signal, завершение работы сервера...\n";
    $running = 0;  # Устанавливаем флаг для завершения основного цикла
    $daemon->close if $daemon;
}

sub new {
    my ($class, $config, $handler) = @_;
    my $self = {
        config => $config,
        handler => $handler,
    };
    return bless $self, $class;
}

# Обработчик завершенных дочерних процессов
sub reap_children {
    while ((my $pid = waitpid(-1, WNOHANG)) > 0) {
        print "Дочерний процесс $pid завершен\n";
    }
}

sub start {
    my ($self) = @_;
    
    # Устанавливаем обработчики сигналов
    $SIG{INT} = \&signal_handler;    # Ctrl+C
    $SIG{TERM} = \&signal_handler;   # kill
    $SIG{CHLD} = \&reap_children;    # Автоматическая обработка завершенных процессов
    
    print "Debug: Starting server with config:\n";
    print "Port: ", $self->{config}->get('port'), "\n";
    
    eval {
        $daemon = HTTP::Daemon->new(
            LocalAddr => 'localhost',
            LocalPort => $self->{config}->get('port'),
            ReuseAddr => 1,
            Timeout   => 60,
        ) or die "Could not create daemon: $!";
        
        print "Сервер запущен на адресе: ", $daemon->url, "\n";
        print "Для завершения работы нажмите Ctrl+C\n";
        
        while ($running) {  # Используем флаг для контроля работы
            if (my $client = $daemon->accept) {
                my $pid = fork();
                
                if (!defined $pid) {
                    warn "Не удалось создать процесс: $!";
                    $client->close;
                    next;
                }
                
                if ($pid == 0) {  # Дочерний процесс
                    $daemon->close;  # Закрываем серверный сокет в дочернем процессе
                    eval {
                        $self->{handler}->handle_request($client);
                    };
                    warn "Error in child process: $@" if $@;
                    $client->close;
                    exit 0;
                }
                
                # Родительский процесс
                $client->close;  # Закрываем клиентский сокет в родительском процессе
            }
        }
    };
    if ($@) {
        die "Server error: $@";
    }
}

END {
    # Закрываем сервер при завершении программы
    if ($daemon) {
        print "Закрытие серверного сокета...\n";
        $daemon->close;
    }
}

1; 