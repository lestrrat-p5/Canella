package Canella::Context;
use Moo;
use Hash::MultiValue;
use Canella::Exec::Local;
use Canella::Log;
use Canella::TaskRunner;
our $CTX;
our $REMOTE;

has concurrency => (
    is => 'rw',
    default => 8,
    isa => sub { die "concurrency must be > 0" unless $_[0] > 0 }
);

has override_parameters => (
    is => 'ro',
    default => sub { Hash::MultiValue->new() }
);

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

has runner => (
    is => 'ro',
    lazy => 1,
    builder => 'build_runner',
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

sub add_role {
    my ($self, $name, %args) = @_;

    if ($args{parameters}) {
        $args{parameters} = Hash::MultiValue->new(%{$args{parameters}});
    }

    $self->roles->set($name, Canella::Role->new(name => $name, %args));
}

sub add_task {
    my $self = shift;
    $self->tasks->set($_[0]->name, $_[0]);
}

sub build_cmd_executor {
    my ($self, @cmd) = @_;

    my $cmd;
    if ($REMOTE) {
        $REMOTE->cmd(\@cmd);
        $cmd = $REMOTE;
    } else {
        $cmd = Canella::Exec::Local->new(cmd => \@cmd);
    }
    return $cmd;
}

sub run_cmd {
    my ($self, @cmd) = @_;

    my $cmd = $self->build_cmd_executor(@cmd);
    $cmd->execute();
    if ($cmd->has_error) {
        croakf("Error executing command: %d", $cmd->error);
    }
    return ($cmd->stdout, $cmd->stderr);
}

sub build_runner {
    return Canella::TaskRunner->new;
}

1;