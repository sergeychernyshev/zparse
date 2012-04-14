sub zeperl_zeperl
{
    my $text = shift;
    my $endtext = '';
    zerror( "zeperl: ...", 0, 'debug' );
    while( $text =~ /\<\?/m )
    {
        $text = $'; my $data = $`; 
        $data =~ s/\\/\\\\/mg; $data =~ s/\"/\\\"/mg; $data =~ s/\n/\\n/mg; $data =~ s/\$/\\\$/mg; $data =~ s/\@/\\\@/mg; 
        $endtext.="print \"$data\";\n";
    
        $text =~ /[\s\n]*\!\>/m or last;
        $text = $'; $data = $`;
        $endtext.="print " if $data =~ s/^=//;
        $endtext.="$data;\n";
    }
    $text =~ s/\\/\\\\/mg; $text =~ s/\"/\\\"/mg; $text =~ s/\n/\\n/mg; $text =~ s/\$/\\\$/mg; $text =~ s/\@/\\\@/mg; 
    $endtext.="print \"$text\";\n";
    
    return $endtext;
}

sub zeperl_zeperleval
{
    my $data = shift;
    my $current_output = <STDOUT>;
    untie *STDOUT;tie *STDOUT, 'zparse2';
    zerror "zeperleval: $zparse2::GLOBAL_ERROR", 254, 'error' unless zsafeeval $data ;
    my $data = <STDOUT>;
    untie *STDOUT;tie *STDOUT, 'zparse2';
    print $current_output;
    return $data;
}

sub zeperl_zprocessdata
{
    my( $data, $mode ) = @_;
    return zeperl( $data ) if $mode==1;
    return &{$zparse2::JUMPTABLE{zeperlsaved_zprocessdata}}( @_ );
}

$zparse2::JUMPTABLE{zeperl} = \&zeperl_zeperl;
sub zeperl { return &{$zparse2::JUMPTABLE{zeperl}}( @_ ); }
$zparse2::JUMPTABLE{zeperleval} = \&zeperl_zeperleval;
sub zeperleval { return &{$zparse2::JUMPTABLE{zeperleval}}( @_ ); }
$zparse2::JUMPTABLE{zeperlsaved_zprocessdata} = $zparse2::JUMPTABLE{zprocessdata};
$zparse2::JUMPTABLE{zprocessdata} = \&zeperl_zprocessdata;
undef %zparse2::file_cache2;
$zparse2::unloaddata = 
    'undef &zeperl; undef &zeperl_zeperl;'
    .'undef &zeperleval; undef &zeperl_zeperleval;'
    .'undef &zeperl_zprocessdata;'
    .'undef %zparse2::file_cache2;';
