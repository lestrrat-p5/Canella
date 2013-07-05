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
    call
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

sub call ($) {
    my $task_name = shift;
    my $ctx = CTX;
    my $task = $ctx->get_task($task_name);
    if (! $task) {
        croakf("Could not find task '%s'", $task_name);
    }
    $ctx->call_task($task, $host);
}

sub current_remote {
    return CTX->stash('current_remote');
}

sub current_task {
    return CTX->stash('current_task');
}

sub get ($) {
    CTX->get_param(@_);
}

sub set ($$) {
    CTX->set_param(@_);
}

sub role ($@) {
    CTX->add_role(@_);
}

sub task ($$) {
    my ($name, $code) = @_;
    CTX->add_task(
        Canella::Task->new(
            name => $name,
            code => $code, 
        )
    );
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

=head1 NAME

Canolla::DSL - DSL For Canolla File

=head1 SYNOPSIS

    use Canolla::DSL;

=head1 PROVIDED FUNCTIONS

=head2 call $task_name

=head2 current_task()

Returns the current task object.

=head2 current_remote()

Returns the current remote object, if available

=head2 get $name

Return the variable of the parameter pointed by $name. Parameters can be
set by calling C<set()>, or by specifying them from the canella command line.

=head2 on_finish \&code

Executes the given C<\&code> at the end of the task.

TODO: Currently this does not run the commands remotely even when you set
on_finish() inside remote().

TODO: Order of execution is not guaranteed. Need to either fix it or document it

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

=head2 remote \&code, $host

Specifies that within the given block C<\&code>, C<run()> commands are run 
on the host specified by C<$host>

=head2 run @cmd

Executes C<@cmd>. If called inside a C<remote()> block, the command will be
executed on the remote host. Otherwise it will be executed locally

=head2 run_local @cmd

Executes C<@cmd>, but always do so on the local machine, regardless of context.

=head2 scp_get @args

Calls Net::OpenSSH::scp_get on the currently connected host. Must be called
inside a C<remote()> block

=head2 scp_put @args

Calls Net::OpenSSH::scp_put on the currently connected host. Must be called
inside a C<remote()> block

=head2 set $name, $value

Sets the parameter C<$name> to point to C<$value>

=head2 task $name, \&code

Declare a new task. There's no notion of hierarchical tasks, but you can
always declare them by hand:

    task "setup:perl" => sub { ... };
    task "setup:nginx" => sub { ... };

=cut