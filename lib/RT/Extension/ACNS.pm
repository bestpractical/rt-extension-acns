use 5.008003;
use strict;
use warnings;

package RT::Extension::ACNS;

our $VERSION = '0.03';

=head1 NAME

RT::Extension::ACNS - parse ACNS messages and extract info into custom fields

=head1 DESCRIPTION

ACNS stands for Automated Copyright Notice System. It's an open source,
royalty free system that universities, ISP's, or anyone that handles large
volumes of copyright notices can implement on their network to increase
the efficiency and reduce the costs of responding to the notices... 
See "http://mpto.unistudios.com/xml/" for more details.

This extension for RT is a configurable scrip that parses ACNS XML from
incomming messages and stores it in custom fields.

=head1 INSTALLATION

    perl Makefile.PL
    make
    make install
    make initdb

In F<RT_SiteConfig.pm>:

    Set(@Plugins, qw(
        RT::Extension::ACNS
        ... other plugins ...
    ));
    Set( %ACNS,
        ... configuration ...
    );

=head1 CONFIGURATION

The scrip is configured thorugh C<%ACNS> config option that described in
details in F<etc/RT_ACNSConfig.pm>.

=cut


=head1 AUTHOR

Ruslan Zakirov E<lt>ruz@bestpractical.comE<gt>

=head1 LICENSE

Under the same terms as perl itself.

=cut

1;
