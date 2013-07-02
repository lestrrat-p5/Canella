package Canella::Context;
use Moo;
use Hash::MultiValue;
use Canella::Exec::Local;
use Canella::Log;
our $CTX;

has parameters => (
    is => 'ro',
    default => sub { Hash::MultiValue->new() }
);

has roles => (
    is => 'ro',
    default => sub { Hash::MultiValue->new() }
);

has tasks => (
    is => 'ro',
    default => sub { Hash::MultiValue->new() }
);

has mode => (
    is => 'rw',
    default => '',
);

has config => (
    is => 'rw'
);

sub load_config {
    my $self = shift;
    my $file = $self->config;
    debugf("Loading config %s", $file);

    do $file;
    if ($@ || $!) {
        croakf("Error loading file: %s", $@ || $!);
    }
}

1;