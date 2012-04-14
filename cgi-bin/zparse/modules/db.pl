require DBI;
sub zconnect { return &{$zparse2::JUMPTABLE{zconnect}}( @_ ); }
sub zexecute { return &{$zparse2::JUMPTABLE{zexecute}}( @_ ); }
sub zquote { return &{$zparse2::JUMPTABLE{zquote}}( @_ ); }

sub zdb_zconnect
{
    my( $ldbuser, $ldbuserpass, $ldbname, $ldbd ) = @_;
    $ldbd = $zparse2::DBD unless defined( $ldbd );
    $ldbname = $zparse2::DBNAME unless defined( $ldbname );
    $ldbuser = $zparse2::DBUSER unless defined( $ldbuser );
    $ldbuserpass = $zparse2::DBUSERPASS unless defined( $ldbuserpass );    
    my $cacheind = "$ldbd\:\:$ldbname\:\:$ldbuser\:\:$ldbuserpass";
    zerror "zconnect: $ldbuser, ".($ldbuserpass?"[password]":"[no password]").", $ldbname, $ldbd", 0, 'debug'; 
    undef $zparse2::cache_dbconn{$cacheind} 
        if( defined $zparse2::cache_dbconn{$cacheind} )
            &&( !$zparse2::cache_dbconn{$cacheind}->ping );                        
    if( !defined( $zparse2::cache_dbconn{$cacheind} ) )
    {
        $zparse2::cache_dbconn{$cacheind} = DBI->connect( "DBI:$ldbd:$ldbname", $ldbuser, $ldbuserpass );
        zerror "zconnect: ".$DBI::errstr, 254, 'error' unless $zparse2::cache_dbconn{$cacheind} || $zparse2::DB_IGNORE_ERRORS;
    }
    return $zparse2::cache_dbconn{$cacheind};
}

sub zdb_zexecute
{
    my ( $query, $dbh ) = @_;
    my $cacheind = "$zparse2::DBD\:\:$zparse2::DBNAME\:\:$zparse2::DBUSER\:\:$zparse2::DBUSERPASS";
    zerror "zexecute: $query", 0, 'debug';
    $dbh = $zparse2::cache_dbconn{$cacheind} unless defined $dbh;
    $dbh = $zparse2::cache_dbconn{$cacheind} if $dbh eq 'default';
    $dbh = zconnect unless ( defined $dbh )&&( $dbh->ping );
    
    my $result = $dbh->prepare( $query )
	|| ((!$zparse2::DB_IGNORE_ERRORS)&&zerror( "zexecute: (prepare) ".$dbh->errstr, 254, 'error' ));
    $result->execute
	|| ((!$zparse2::DB_IGNORE_ERRORS)&&zerror( "zexecute: (execute) ".$dbh->errstr, 254, 'error' ));
    return $result
}

sub zdb_zquote
{
    my ( $text, $dbh ) = @_;
    my $cacheind = "$zparse2::DBD\:\:$zparse2::DBNAME\:\:$zparse2::DBUSER\:\:$zparse2::DBUSERPASS";
    zerror "zquote: $text", 0, 'debug';
    $dbh = $zparse2::cache_dbconn{$cacheind} unless defined $dbh;
    $dbh = zconnect unless ( defined $dbh )&&( $dbh->ping );
    return $dbh->quote( $text );
}

sub zdb_zchildexit
{
    foreach my $key ( keys %zparse2::cache_dbconn )
    {
	$zparse2::cache_dbconn{$key}->disconnect if defined( $zparse2::cache_dbconn{$key} );
	undef $zparse2::cache_dbconn{$key};
    }
    return &{$zparse2::JUMPTABLE{zdbsaved_zchildexit}}( @_ ); 
}

sub zdb_zbefore_actual_process
{    
    if( $zparse2::MOD_PERL )
    {
	$zparse2::DBD = 'mysql';
	$zparse2::DBNAME = '';
	$zparse2::DBUSER = '';
	$zparse2::DBUSERPASS = '';
        $zparse2::DBD = $REQ->dir_config( 'ZDBD' ) if defined $REQ->dir_config( 'ZDBD' );
        $zparse2::DBNAME = $REQ->dir_config( 'ZDBName' ) if defined $REQ->dir_config( 'ZDBName' );
        $zparse2::DBUSER = $REQ->dir_config( 'ZDBUser' ) if defined $REQ->dir_config( 'ZDBUser' );
        $zparse2::DBUSERPASS = $REQ->dir_config( 'ZDBUserPass' ) if defined $REQ->dir_config( 'ZDBUserPass' );
    }
    else
    {
    	$zparse2::DBD = 'mysql' unless defined $zparse2::DBD;
	$zparse2::DBNAME = '' unless defined $zparse2::DBNAME;
	$zparse2::DBUSER = '' unless defined $zparse2::DBUSER;
	$zparse2::DBUSERPASS = '' unless defined $zparse2::DBUSERPASS;
    }
    return &{$zparse2::JUMPTABLE{zdbsaved_zbefore_actual_process}}( @_ );
}

$zparse2::JUMPTABLE{zconnect} = \&zdb_zconnect;
$zparse2::JUMPTABLE{zexecute} = \&zdb_zexecute;
$zparse2::JUMPTABLE{zquote} = \&zdb_zquote;
$zparse2::JUMPTABLE{zdbsaved_zchildexit} = $zparse2::JUMPTABLE{zchildexit};
$zparse2::JUMPTABLE{zchildexit} = \&zdb_zchildexit;
$zparse2::JUMPTABLE{zdbsaved_zbefore_actual_process} = $zparse2::JUMPTABLE{zbefore_actual_process};
$zparse2::JUMPTABLE{zbefore_actual_process} = \&zdb_zbefore_actual_process;
$zparse2::JUMPTABLE{zdbsaved_zsetdefaults} = $zparse2::JUMPTABLE{zsetdefaults};
$zparse2::JUMPTABLE{zsetdefaults} = \&zdb_zsetdefaults;

$zparse2::unloaddata = 'undef &zquote; undef &zconnect; undef &zexecute; undef &zdb_zquote; undef &zdb_zconnect; undef &zdb_zexecute; undef &zdb_zsetdefaults;';
