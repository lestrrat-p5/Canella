package Canella::DSL;
use strict;
use Exporter 'import';
use Canella::BlockGuard;
use Canella::Exec::Local;
use Canella::Exec::Remote;
use Canella::Log;
use Canella::Role;
use Canella::Task;
our $REMOTE;
our @EXPORT = qw(
    get
    on_finish
    role
    remote
    run
    set
    task
);

sub Canella::define {
    my $class = shift;
    $_[0]->();
}

sub get (@) {
    $Canella::Context::CTX->parameters->get(@_);
}

sub set (@) {
    $Canella::Context::CTX->parameters->set(@_);
}

sub role ($@) {
    $Canella::Context::CTX->add_role(@_);

}

sub task ($$) {
    my ($name, $task_def) = @_;

    my $ref = ref $task_def;
    my %map;
    if ($ref eq 'CODE') {
        $Canella::Context::CTX->add_task(
            Canella::Task->new(
                name => $name,
                code => $task_def, 
            )
        );
    } elsif ($ref eq 'HASH') {
        foreach my $subname (keys %$task_def) {
            $Canella::Context::CTX->add_task(
                Canella::Task->new(
                    name => "$name:$subname",
                    code => $task_def->{$subname},
                )
            );
        }
    }
}

sub run(@) {
    $Canella::Context::CTX->run_cmd(@_);
}

sub remote (&$) {
    my ($code, $host) = @_;

    local $Canella::Context::REMOTE = Canella::Exec::Remote->new(
        host => $host,
        user => $Canella::Context::CTX->parameters->get('user'),
    );

    $code->($host);
}

sub on_finish(&;$) {
    my ($code, $name) = @_;
    # on_finish always fires

    my $guard = Canella::BlockGuard->new(
        name => $name,
        code => $code,
        should_fire_cb => sub { 1 }
    );
    $Canella::Task::CURRENT->add_guard($guard->name, $guard);
}

sub on_error (&;$) {
    my ($code, $name) = @_;
    # should only fire if we errored out
    my $guard = Canella::BlockGuard->new(
        name => $name,
        code => $code,
        should_fire_cb => sub { $_[1]->has_error }
    );
    $Canella::Task::CURRENT->add_guard($guard->name, $guard);
}


1;

__END__

=head1 PROVIDED FUNCTIONS

=head2 role $name, @spec;

    role 'www' => (
        hosts => [ qw(host1 host2 host3) ]
    );

    role 'www' => (
        hosts => sub { ... dynamically load hosts },
    );

    role 'www' => (
        hosts => ...,
        params => { ... local parameters ... }
    );

=cut