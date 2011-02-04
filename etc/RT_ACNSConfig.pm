=head1 RT::Extension::ACNS specific settings

=head2 %ACNS

A hash with Defaults and Map keys.

Defaults are used for every ACNS message, it's a hash
with ( custom field => value ) pairs. For example:

    Set( %ACNS => 
        Defaults => {
            'Custom Field X' => 'default value',
            ...
        },
        Map => ...
    );

Map is hash with (custom field => path) pairs, where path
is an array reference with node names from ACNS XML. More
on paths below.

    Set( %ACNS => 
        Defaults => { ... },
        Map => {
            'A custom field' => ['element', 'element', 'element'],
            ...
        },
    );

Path in the map follows XML structure strictly with some tricks.

=over 4

=item * don't need to list Infringement as first element, for example:

    # store text of Infringement/Case/ID in Case custom field
    Set( %ACNS => 
        Map => {
            Case => [qw(Case ID)],
        },
    );

=item * ACNS specification has repeated elements, for example there may be
multiple Item records in Infringement/Content section. Such elements should
be followed by '1', '-1' or '*' to pick first, last or all sub-items
correspondingly. For example:

    # store all URLs in URLs custom field
    Set( %ACNS => 
        Map => {
            URLs => [qw(Content Item * URL)],
        },
    );

If you picked all elements then multiple values stored in the custom field,
but if the CF can store only one value then values joined with new line
character before storing.

=item * a few elements in ACNS schema has attributes and text. Follow element
name with attribute name to store text. For example:

    # store last notice timestamp
    Set( %ACNS => 
        Map => {
            LastNotice => [qw(History Notice -1 TimeStamp)],
        },
    );

=back

=cut

Set( %ACNS => 
    Defaults => { },
    Map => { },
);
