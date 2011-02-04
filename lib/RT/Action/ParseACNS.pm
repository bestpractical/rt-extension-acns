use strict;
use warnings;

package RT::Action::ParseACNS;
use base 'RT::Action';

use XML::LibXML;
use Parse::ACNS;

sub Prepare {
    my $self = shift;

    my $content = $self->TransactionObj->Content;
    $content =~ s/^.*Start ACNS XML\n//s
        or $RT::Logger->warn("No 'Start ACNS XML' marker");
    $content =~ s/- -+End ACNS XML.*$//s
        or $RT::Logger->warn("No 'End ACNS XML' marker");

    my $xml = XML::LibXML->new->parse_string( $content );
    my $data = Parse::ACNS->new->parse( $xml );
    $self->{'ACNS'} = $self->MapDataOverCFs( $data );
    return 1;
}

sub Commit {
    my $self = shift;
    
    $self->UpdateCustomFields( $self->{'ACNS'} );
    return 1;
}

sub UpdateCustomFields {
    my $self = shift;
    my $values = shift;
    while ( my ($name, $value) = each %$values ) {
        my $cf = $self->TicketObj->LoadCustomFieldByIdentifier( $name );
        unless ( $cf && $cf->id ) {
            $RT::Logger->error( "Ticket #". $self->TicketObj->id . "has no custom field '$name'");
            next;
        }
        $self->UpdateCustomField( $cf, $value);
    }
}

sub UpdateCustomField {
    my $self = shift;
    my $cf = shift;
    my $value = shift;

    my $ticket = $self->TicketObj;

    if ( $cf->MaxValues == 1 ) {
        if ( $value ) {
            if ( ref $value ) {
                $RT::Logger->debug(
                    "Custom Field can have only one value, but we got"
                    ." several values from ACNSS data. Joining with newlines."
                );
                $value = join "\n", @$value;
            }
            my ($status, $msg) = $ticket->AddCustomFieldValue(
                Field => $cf, Value => $value,
            );
            $RT::Logger->error("Couldn't set CF: $msg") unless $status;
        }
        elsif ( $ticket->CustomFieldValues->First ) {
            my ($status, $msg) = $ticket->DeleteCustomFieldValue(
                Field => $cf,
                Value => $ticket->FirstCustomFieldValue( $cf ),
            );
            $RT::Logger->error("Couldn't delete CF value: $msg")
                unless $status;
        }
    }
    else {
        unless ( $value ) {
            foreach my $value ( @{ $ticket->CustomFieldValues($cf)->ItemsArrayRef } ) {
                my ($status, $msg) = $ticket->DeleteCustomFieldValue(
                    Field   => $cf, ValueId => $value->id,
                );
                $RT::Logger->error("Couldn't delete CF value: $msg")
                    unless $status;
            }
        }
        else {
            my @new = ref $value? (@$value) : ($value);
            my @old = @{ $ticket->CustomFieldValues($cf)->ItemsArrayRef };

            my @tmp;
            foreach my $new ( @new ) {
                next if grep lc $_->Content eq $new, @old;
                push @tmp, $new;
            }
            foreach my $old ( splice @old ) {
                my $oldv = lc $old->Content;
                next unless grep $oldv eq lc $_, @new;
                push @old, $old;
            }
            @new = @tmp;

            foreach my $value ( @old ) {
                my ($status, $msg) = $ticket->DeleteCustomFieldValue(
                    Field   => $cf, ValueId => $value->id,
                );
                $RT::Logger->error("Couldn't delete CF value: $msg")
                    unless $status;
            }
            foreach my $value ( @new ) {
                my ($status, $msg) = $ticket->AddCustomFieldValue(
                    Field   => $cf, Value => $value,
                );
                $RT::Logger->error("Couldn't add CF value: $msg")
                    unless $status;
            }
        }
    }
}

sub MapDataOverCFs {
    my $self = shift;
    my $data = shift;

    my %config = RT->Config->Get('ACNS');

    my %res;
    %res = %{ $config{'Defaults'} } if $config{'Defaults'};
    return \%res unless $config{'Map'};

    while ( my ($cf, $path) = each %{ $config{'Map'} } ) {
        my @tmp = grep defined && length, $self->ResolveMapEntry(
            Data => $data,
            Path => $path,
            CustomField => $cf,
        );
        $res{ $cf } = @tmp > 1 ? [ @tmp ] : @tmp? $tmp[0] : undef;
    }
    return \%res;
}

sub ResolveMapEntry {
    my $self = shift;
    my %args = @_;

    my $data = $args{'Data'};
    my @path = @{ $args{'Path'} };
    my @done = @{ $args{'Done'} || [] };

    $RT::Logger->debug("Searching for '". join('.', @path) ."' in ACNS data" )
        unless @done; # log once

    while ( my $e = shift @path ) {
        unless ( ref $data ) {
            $RT::Logger->error("Reached terminal element in data");
            return ();
        }
        elsif ( 'HASH' eq ref $data ) {
            unless ( exists $data->{ $e } ) {
                $RT::Logger->debug(
                    "No entry for '". join('.', @done, $e)
                    ."' in ACNS data. Ignoring"
                );
                return ();
            }
            else {
                push @done, $e;
                $data = $data->{ $e };
            }
        }
        elsif ( 'ARRAY' eq ref $data ) {
            if ( $e eq '*' ) {
                push @done, $e;
                my @res;
                foreach my $data_point ( @{$data} ) {
                    push @res, $self->ResolveMapEntry(
                        Data => $data_point,
                        Path => [ @path ],
                        Done => \@done,
                    );
                }
                return @res;
            }
            elsif ( $e eq '1' || $e eq '-1' ) {
                push @done, $e;
                $data = $data->[ $e > 0? 0 : -1 ];
            }
            else {
                $RT::Logger->error(
                    "Reached list '". join('.', @done)
                    ."', but selector ($e) is not *, 1 or -1"
                );
                return ();
            }
        }
    }

    unless ( ref $data ) {
        return ($data);
    }
    elsif ( 'HASH' eq ref $data && exists $data->{'_'} ) {
        return ($data->{'_'});
    }
    else {
        $RT::Logger->error(
            "Found '". join('.', @done)
            ."', but it's not an end of the ACNS data"
        );
        return ();
    }
}

1;
