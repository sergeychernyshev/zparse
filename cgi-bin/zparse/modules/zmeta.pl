sub zmeta_zdefmeta
{
    my ( $name, $body ) = @_;
    $zparse2::zmetadef{$name}=$body;
}

sub zmeta_zloadmeta
{
    my @files=split(/\s*;\s*/,shift);
    foreach my $file (@files)
    {
        my $text = zloadfile( $file, 0 );
        while( $text =~ /\<(metax?) (\w+)\>/m )
        {
	    $text = $';
	    my $mode = $1;
	    my $name = $2;

	    $text =~ /\<\/meta\>/;
	    $text = $'; my $body = $`;
	    if( $mode eq 'meta' )
	    {
		$body =~ s/^(\n|\s)*//mg;
		$body =~ s/(\n|\s)*$//mg;
		$body =~ s/\n(\s*)/\n/mg;
	    }
	    zdefmeta( $name, $body );
	}
    }
}

sub zmeta_zmeta
{
    my $text = shift;
    my $endtext = '';
    zerror 'zmeta:...', 0, 'debug';
    while( $text =~ /\<\%/m )
    {
	$text = $'; my $data = $`;
	$endtext.=$data;
	
        $text =~ /\%\>/m or last;
        $text = $'; $data = $`;
	$data =~ /^\s*(\w+)(\s+(.*))?$/;
	my @params;
	print "undefined meta \"$1\"\n" unless defined( $zparse2::zmetadef{$1} );
	$data = $zparse2::zmetadef{$1};
	my ($params,$sparam,$quotemode,$char,$order,$quotechar)=($3,'',0,0,1,'');
	while( $char<= length( $params ) )
	{
	    my $c = substr($params, $char, 1);
	    if( $quotemode )
	    {
		$sparam.=$c;
		$quotemode=0 if( ( $c eq $quotechar ) && ( substr($params, $char-1, 1) ne '\\' ) );
		next;
	    }
    	    if( $c =~ /(\s|\n)/ ) { next; }
	    elsif( ($c eq '"') || ($c eq '\'') ) { $quotemode=1; $quotechar=$c; }
	    elsif( $c eq ',' )
	    {
	        $params[$order++] = $sparam;
	        $sparam='';
	        next;
	    }
	    $sparam.=$c;
	} continue { $char++; }
	
	$params[$order]=$sparam if $sparam;
	while( $order > 0 )
	{
	    $data =~ s/\[\%$order\%\]/$params[$order]/mg;
	    $order--;
	}
	$endtext.=zmeta( $data );
    }
    $endtext.=$text;
    return $endtext;
}

sub zmeta_zprocessdata
{
    my( $data, $mode ) = @_;
    return zmeta( $data ) if $mode==2;
    return zprocessdata( zmeta( $data ), 1 ) if $mode==3;
    return zmeta( zprocessdata( $data, 1 ) ) if $mode==4;
    return &{$zparse2::JUMPTABLE{zmetasaved_zprocessdata}}( @_ );
}

sub zmeta_zbefore_actual_process
{
    my $URI = $_[0];
    my $metafile = zmap( $URI, "$zparse2::DATA_FILES_DIR/script_table", 'meta', $ENV{QUERY_STRING} );
    zloadmeta( $metafile ) if $metafile;
    return &{$zparse2::JUMPTABLE{zmetasaved_zbefore_actual_process}}( @_ );
}

$zparse2::JUMPTABLE{zmeta} = \&zmeta_zmeta;
sub zmeta { return &{$zparse2::JUMPTABLE{zmeta}}( @_ ); }
$zparse2::JUMPTABLE{zdefmeta} = \&zmeta_zdefmeta;
sub zdefmeta { return &{$zparse2::JUMPTABLE{zdefmeta}}( @_ ); }
$zparse2::JUMPTABLE{zloadmeta} = \&zmeta_zloadmeta;
sub zloadmeta { return &{$zparse2::JUMPTABLE{zloadmeta}}( @_ ); }
$zparse2::JUMPTABLE{zmetasaved_zprocessdata} = $zparse2::JUMPTABLE{zprocessdata};
$zparse2::JUMPTABLE{zprocessdata} = \&zmeta_zprocessdata;
$zparse2::JUMPTABLE{zmetasaved_zbefore_actual_process} = $zparse2::JUMPTABLE{zbefore_actual_process};
$zparse2::JUMPTABLE{zbefore_actual_process} = \&zmeta_zbefore_actual_process;

undef %zparse2::file_cache2;
$zparse2::unloaddata = 
    'undef &zmeta; undef &zmetadef; undef &zmetaload; undef &zmeta_zmeta;'
    .'undef &zmeta_zmetadef; undef &zmeta_zmetaload; undef &zmeta_zprocessdata;'
    .'undef &zmeta_zbefore_actual_process;'
    .'undef %zparse2::file_cache2; undef %zparse2::zmetadef;';
