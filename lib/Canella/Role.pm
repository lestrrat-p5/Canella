package Canella::Role;
use Moo;
use Hash::MultiValue;

has name => (is => 'ro', required => 1);
has hosts => (is => 'ro', required => 1);
has parameters => (is => 'ro', default => sub { Hash::MultiValue->new });

sub get_hosts {
    my $self = shift;
    my $hosts = $self->hosts;
    if (ref $hosts eq 'CODE') {
        return $hosts->();
    }
    return $hosts;
}
    

1;