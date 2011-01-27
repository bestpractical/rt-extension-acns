use strict;
use warnings;

package RT::Condition::ACNSMessage;
use base 'RT::Condition';

sub IsApplicable {
    my $self = shift;
    return $self->TransactionObj->Content =~ /Start ACNS XML/;
}

1;
