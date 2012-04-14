sub multipage_init
{
    my ($query, $url_tmpl, $name_tmpl, $rowsperpage) = @_;
    $rowsperpage = 10 unless defined $rowsperpage;
    $root->{rowsperpage} = $rowsperpage;
    $root->{page} = 0;
    if( zcheckparam2 'page', '^\d+$', 'simple' )
    {
        $root->{page} = $root->{nparams}->{page}->{value};
    }
    my $data = zexecute( $query )->fetch;
    my $totalrows = $data?($data->[0]):(0);
    $root->{totalrows} = $totalrows;
    if( $totalrows>$rowsperpage )
    {
        my $order=0;
        for( my $i=0; $i<$totalrows; $i+=$rowsperpage )
        {
            my $end = $i+$rowsperpage;
            $root->{pages}->{$order}->{url} = sprintf $url_tmpl, $order;
            $root->{pages}->{$order}->{name} = sprintf $name_tmpl, ($i+1),($end>$totalrows?$totalrows:$end);
            $order++;
        }    
    }
}

sub multipage_query
{
    my( $query, $url ) = @_;
    my $firstrow = $root->{page}*$root->{rowsperpage};
    $root->{firstrow} = $firstrow;
    zredirect $url if ($firstrow> $root->{totalrows})||($firstrow<0);
    return $query." limit $firstrow,".$root->{rowsperpage};
}

$zparse2::unloaddata = 'undef &multipage_init; undef &multipage_query;';
