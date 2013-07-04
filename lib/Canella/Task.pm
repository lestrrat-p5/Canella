package Canella::Task;
use Moo;
our $CURRENT;

has code => (
    is => 'ro',
    required => 1,
);

has name => (
    is => 'ro',
    required => 1,
);

sub add_guard;

sub execute {
    my $self = shift;

    my %guards;
    no warnings 'redefine';
    local *add_guard = sub {
        $guards{$_[1]} = $_[2];
    };

    eval {
        local $CURRENT = $self;
        $self->code->(@_);
    };
    my $E = $@;

    foreach my $guard (values %guards) {
        if (! $guard->should_fire($self)) {
            $guard->cancel;
        }
    }

    die $E if $E;
}

1;
