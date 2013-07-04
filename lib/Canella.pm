package Canella;
use 5.008005;
use strict;
use warnings;
use Exporter 'import';
our @EXPORT_OK = qw(CTX);

our $VERSION = "0.01";

sub CTX { $Canella::Context::CTX }

1;
__END__

=encoding utf-8

=head1 NAME

Canella - Simple Deploy Tool A La Cinnamon

=head1 SYNOPSIS

    use Canella::DSL;

    Canella->define({
        role "production" => (
            hosts => [ qw(host1 host2) ],
        );

        task "setup:perl" => sub {
            my $host = shift;
            remote {
                on_finish { run "rm", "-rf", "xbuild" };
                run "git", "clone", "git://github.com/tagomoris/xbuild.git";
                run "xbuild/perl-install", "5.16.3", "/opt/local/perl-5.16";
            } $host;
        };

        task "setup:apache" => sub {
            my $host = shift;
            remote {
                    run "yum", "install", "apache2";
            } $host;
        };

        task deploy => sub {
            my $host = shift;
            remote {
                my $dir = get "deploy_to";
                run "cd $dir && git pull";
            } $host;
        };

        task "restart:app" => sub {
            my $host = shift;
            remote {
                run "svc -h /service/myapp";
            } $host;
        };
        task "restart:apache" => sub {
            my $host = shift;
            remote {
                run "apachectl restart";
            } $host;
        };
    };

=head1 INVOCATION

Based on the config file shown in SYNOPSIS, you can invoke commands like so:

    # Run setup on production servers
    canella --config=/path/to/config.pl production setup:apache setup:perl

    # Run deploy (sync files) on production servers
    canella --config=/path/to/config.pl production sync

    # Restart apps (controlled via daemontools)
    canella --config=/path/to/config.pl production restart:app

=head1 DESCRIPTION

Canella is a simple deploy tool, based on L<Cinnamon>

=head1 LICENSE

Copyright (C) Daisuke Maki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Daisuke Maki E<lt>daisuke@endeworks.jpE<gt>

=cut

