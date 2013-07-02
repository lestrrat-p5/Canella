requires 'perl', '5.008001';

requires 'AnyEvent';
requires 'Hash::MultiValue';
requires 'IPC::Run';
requires 'Guard';
requires 'Log::Minimal';
requires 'Moo';
requires 'Net::OpenSSH';
requires 'Carp::Always';
on 'test' => sub {
    requires 'Test::More', '0.98';
};

