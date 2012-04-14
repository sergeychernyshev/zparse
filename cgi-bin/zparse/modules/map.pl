sub zmap_zmapdef
{
    my ( $tablename, $maptype, $srcre, $dstre, $qryre ) = @_;
    $qryre = '.*' unless defined( $qryre );
    my $order = 0;
    foreach my $key ( keys %{$map_cache{$tablename}->{$maptype}} )
    {
        $order = $key if $key>$order;
    }
    undef $map_cache2{$tablename};
    $map_cache{$tablename}->{$maptype}->{++$order} = [ $srcre, $dstre, $qryre ];
}

sub zmap_zmapclear
{
    my $tablename = shift;
    undef $map_cache{$tablename};
    undef $map_cache2{$tablename};
}

sub zmapdef { return &{$zparse2::JUMPTABLE{zmapdef}}( @_ ); }
sub zmapclear { return &{$zparse2::JUMPTABLE{zmapclear}}( @_ ); }

$zparse2::JUMPTABLE{zmapdef} = \&zmap_zmapdef;
$zparse2::JUMPTABLE{zmapclear} = \&zmap_zmapclear;

$zparse2::unloaddata=
    'undef &zmapdef; undef &zmap_zmapdef;'
    .'undef &zmapclear; undef &zmap_zmapclear';
