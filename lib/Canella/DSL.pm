package Canella::DSL;
use strict;
use Exporter 'import';
use Canella 'CTX';
use Canella::BlockGuard;
use Canella::Exec::Local;
use Canella::Exec::Remote;
use Canella::Log;
use Canella::Role;
use Canella::Task;
our $REMOTE;
our @EXPORT = qw(
    current_task
    current_remote
    get
    on_finish
    role
    remote
    run
    run_local
    scp_get
    scp_put
    set
    task
);

sub Canella::define {
    my $class = shift;
    $_[0]->();
}

sub current_remote {
    return CTX->stash('current_remote');
}

sub current_task {
    return CTX->stash('current_task');
}

sub get (@) {
    CTX->parameters->get(@_);
}

sub set (@) {
    CTX->parameters->set(@_);
}

sub role ($@) {
    CTX->add_role(@_);
}

sub task ($$) {
    my ($name, $task_def) = @_;

    my $ref = ref $task_def;
    my %map;
    if ($ref eq 'CODE') {
        CTX->add_task(
            Canella::Task->new(
                name => $name,
                code => $task_def, 
            )
        );
    } elsif ($ref eq 'HASH') {
        foreach my $subname (keys %$task_def) {
            CTX->add_task(
                Canella::Task->new(
                    name => "$name:$subname",
                    code => $task_def->{$subname},
                )
            );
        }
    }
}

sub run(@) {
    CTX->run_cmd(@_);
}

sub run_local(@) {
    my $stash = CTX->stash;
    local $stash->{current_remote};
    CTX->run_cmd(@_);
}

sub remote (&$) {
    my ($code, $host) = @_;

    my $ctx = CTX;
    $ctx->stash(current_remote => Canella::Exec::Remote->new(
        host => $host,
        user => $ctx->parameters->get('user'),
    ));

    $code->($host);
}

sub scp_get(@) {
    my $remote = current_remote;
    {
        local $Log::Minimal::AUTODUMP = 1;
        infof "[%s :: executing] scp_get %s", $remote->host, \@_;
    }
    $remote->connection->scp_get(@_);
}

sub scp_put(@) {
    my $remote = current_remote;
    {
        local $Log::Minimal::AUTODUMP = 1;
        infof "[%s :: executing] scp_put %s", $remote->host, \@_;
    }
    $remote->connection->scp_put(@_);
}

sub on_finish(&;$) {
    my ($code, $name) = @_;
    # on_finish always fires

    my $guard = Canella::BlockGuard->new(
        name => $name,
        code => $code,
        should_fire_cb => sub { 1 }
    );
    current_task->add_guard($guard->name, $guard);
}

sub on_error (&;$) {
    my ($code, $name) = @_;
    # should only fire if we errored out
    my $guard = Canella::BlockGuard->new(
        name => $name,
        code => $code,
        should_fire_cb => sub { $_[1]->has_error }
    );
    current_task->add_guard($guard->name, $guard);
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