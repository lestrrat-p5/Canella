package Canella::CLI;
use Moo;
use Canella::Context;
use Canella::Log;
use Getopt::Long ();
use Guard;

sub parse_argv {
    my ($self, $ctx, @argv) = @_;

    local @ARGV = @argv;
    my $p = Getopt::Long::Parser->new;
    $p->configure(qw(
        posix_default
        no_ignore_case
        auto_help
    ));
    my @optspec = qw(
        config=s
        set=s%
    );
    my $opts = {};
    if (! $p->getoptions($opts, @optspec)) {
        croakf("Failed to parse command line");
    }

    my $set_vars = delete $opts->{set} || {};
    foreach my $var_name (keys %$set_vars) {
        debugf("Setting variable from command line %s -> %s", $var_name, $set_vars->{$var_name});
        $ctx->parameters->set($var_name, $set_vars->{$var_name});
    }

    foreach my $key (keys %$opts) {
        $ctx->$key($opts->{$key});
    }

    return @ARGV; # remaining
}

sub dump_config {
    # XXX TODO
}

sub run {
    my ($self, @argv) = @_;

    my $ctx = Canella::Context->new;
    local $Canella::Context::CTX = $ctx;
    my @remaining = $self->parse_argv($ctx, @argv);
    if (@remaining < 2) {
        croakf("need a role and a task");
    }

    $ctx->load_config();

    if ($ctx->mode eq 'dump') {
        $ctx->dump_config();
        return;
    }

    my $role_name = shift @remaining;
    my $role = $ctx->roles->get($role_name);
    if (! $role) {
        croakf("Unknown role %s", $role_name);
    }
    my @tasks;
    foreach my $task_name (@remaining) {
        my $task = $ctx->tasks->get($task_name);
        if (! $task) {
            croakf("Unknown task %s", $task_name);
        }
        push @tasks, $task;
    }
    $ctx->parameters->set(role => $role_name);

    # Register per-role parameters, only if they are not set
    my %has_key = map { ($_ => 1) } $ctx->parameters->keys;
    my %tmp_key;
    foreach my $param_key ($role->parameters->keys) {
        if ($has_key{$param_key}) {
            next;
        }
        debugf("Applying role default parameter %s", $param_key);
        $tmp_key{$param_key} = $ctx->parameters->get($param_key);
        $ctx->parameters->set($param_key, $role->parameters->get($param_key));
    }
    my $block_ctx = guard {
        my $params = $ctx->parameters;
        foreach my $param_key (keys %tmp_key) {
            debugf("Restoring paramter value for %s", $param_key);
            $params->set($param_key, $tmp_key{$param_key});
        }
    };
    my $hosts = $role->get_hosts();
    foreach my $host (@$hosts) {
        foreach my $task (@tasks) {
            local $@;
            eval { $task->execute($host) };
            if (my $E = $@) {
                critf("[%s] %s", $host, $E);
            }
        }
    }
}

1;
