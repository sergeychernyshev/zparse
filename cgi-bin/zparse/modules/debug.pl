sub zdebug_zdumpvar
{
    my( $varname, $expr, $level, $flag ) = @_;
    $expr = $varname unless defined $expr;
    $level = 0 unless defined $level;
    $flag = 'debug' unless defined $flag;
    zerror "zdumpvar: $varname: <font color=blue>'".eval( $expr )."'</font>", $level, $flag;
}

sub zdebug_zdump_params
{
    foreach my $p ( keys %{$root->{params}} )
    {
        if( defined $root->{params}->{$p}->{1} )
        {
            foreach my $k ( keys %{$root->{params}->{$p}} )
            {
                zerror "zdump_params: $p [$k]='".$root->{params}->{$p}->{$k}.'\'';
            }
        }
        else
        {
            zerror "zdump_params: $p='".$root->{params}->{$p}.'\'';
        }
    }
}

sub zdebug_zdump_nparams
{
    foreach my $p ( keys %{$root->{nparams}} )
    {
        zerror 'zdump_nparams:param: ->', 0, 'debug';
        if( $root->{nparams}->{$p}->{type} eq 'file' )
        {
            zerror 'zdump_nparams:&nbsp;&nbsp;type: file', 0, 'debug';
            zerror 'zdump_nparams:&nbsp;&nbsp;name: \''.$root->{nparams}->{$p}->{name}.'\'', 0, 'debug';
            zerror 'zdump_nparams:&nbsp;&nbsp;filename: \''.$root->{nparams}->{$p}->{filename}.'\'', 0, 'debug';
            zerror 'zdump_nparams:&nbsp;&nbsp;tmpfilename: \''.$root->{nparams}->{$p}->{tmpfilename}.'\'', 0, 'debug';
        }
        elsif( $root->{nparams}->{$p}->{type} eq 'simple' )
        {
            zerror 'zdump_nparams:&nbsp;&nbsp;type: simple', 0, 'debug';
            zerror 'zdump_nparams:&nbsp;&nbsp;name: \''.$root->{nparams}->{$p}->{name}.'\'', 0, 'debug';
            zerror 'zdump_nparams:&nbsp;&nbsp;value: \''.$root->{nparams}->{$p}->{value}.'\'', 0, 'debug';
        }
        elsif( $root->{nparams}->{$p}->{type} eq 'array' )
        {
            zerror 'zdump_nparams:&nbsp;&nbsp;type: array', 0, 'debug';
            zerror 'zdump_nparams:&nbsp;&nbsp;name: \''.$root->{nparams}->{$p}->{name}.'\'', 0, 'debug';
            zerror 'zdump_nparams:&nbsp;&nbsp;n: \''.$root->{nparams}->{$p}->{n}.'\'', 0, 'debug';
            for( my $i=1; $i<= $root->{nparams}->{$p}->{n}; $i++ )
            {
                zerror 'zdump_nparams:&nbsp;&nbsp;value: \''.$root->{nparams}->{$p}->{$i}->{value}.'\'', 0, 'debug';
            }
        }
        elsif( $root->{nparams}->{$p}->{type} eq 'filearray' )
        {
            zerror 'zdump_nparams:&nbsp;&nbsp;type: filearray', 0, 'debug';
            zerror 'zdump_nparams:&nbsp;&nbsp;name: \''.$root->{nparams}->{$p}->{name}.'\'', 0, 'debug';
            zerror 'zdump_nparams:&nbsp;&nbsp;n: \''.$root->{nparams}->{$p}->{n}.'\'', 0, 'debug';
            for( my $i=1; $i<= $root->{nparams}->{$p}->{n}; $i++ )
            {
                zerror 'zdump_nparams:&nbsp;&nbsp;filename: \''.$root->{nparams}->{$p}->{$i}->{filename}.'\'', 0, 'debug';
                zerror 'zdump_nparams:&nbsp;&nbsp;tmpfilename: \''.$root->{nparams}->{$p}->{$i}->{tmpfilename}.'\'', 0, 'debug';
            }
        }
    }
}

sub zdebug_zdump_cookies
{
    foreach my $k ( %{$root->{cookies}} )
    {
        zerror "zdump_cookies: $k=".$root->{cookies}->{$k}, 0, 'debug';
    }
}

sub zdebug_zdump_env
{
    foreach my $k ( sort {$a cmp $b} keys %ENV )
    {
        zerror 'zdump_env: $ENV{'.$k.'}=<font color="blue">\''.$ENV{$k}.'\'</font>', 0, 'debug';
    }
}

sub zdebug_zbefore_actual_process
{
    my $rv = &{$zparse2::JUMPTABLE{zdebugsaved_zbefore_actual_process}}( @_ );
    
    if ( $zparse2::MOD_PERL )
    {
    	zerror 'z: REQ=<font color="blue"><pre>'.$REQ->as_string.'</pre></font>', 0, 'debug';
    }   

    zdumpvar( '$zparse2::MAX_MAP_ITERATIONS' );
    zdumpvar( '$zparse2::DOCUMENT_ROOT' );
    zdumpvar( '$zparse2::ZLOCALE' );
    zdumpvar( '$zparse2::MODULES' );
    zdumpvar( '$zparse2::DEFAULT_DATA_MODE' );
    zdumpvar( '$zparse2::DEFAULT_PERL_MODE' );
    zdumpvar( '$zparse2::MOD_PERL' );
    zdumpvar( '$zparse2::ZERRORONINCLUDE' );
    zdumpvar( '$zparse2::ZPARSEPARAMS' );
    zdumpvar( '$zparse2::DEBUG' );
    zdumpvar( '$zparse2::LOGLEVEL' );
    zdumpvar( '$zparse2::MAX_FILE_LENGTH' );
    zdumpvar( '$zparse2::MODULES_PATH' );
    zdumpvar( '$zparse2::DATA_FILES_DIR' );

    zdumpvar( '$zparse2::DBD' );
    zdumpvar( '$zparse2::DBNAME' );
    zdumpvar( '$zparse2::DBUSER' );
    zdumpvar( '$zparse2::DBUSERPASS' );

    zdumpvar( '$zparse2::GUARD' );
    zdumpvar( '$zparse2::GUARDDBNAME' );
    zdumpvar( '$zparse2::GUARDDBUSER' );
    zdumpvar( '$zparse2::GUARDDBUSERPASS' );
    zdumpvar( '$zparse2::GUARDPATH' );
    zdumpvar( '$zparse2::GUARDALLOWANONYMOUS' );
    zdumpvar( '$zparse2::GUARDANONYMOUSUSER' );

    zdump_env();

    return $rv;
}

$zparse2::JUMPTABLE{zdumpvar} = \&zdebug_zdumpvar;
$zparse2::JUMPTABLE{zdump_params} = \&zdebug_zdump_params;
$zparse2::JUMPTABLE{zdump_nparams} = \&zdebug_zdump_nparams;
$zparse2::JUMPTABLE{zdump_cookies} = \&zdebug_zdump_cookies;
$zparse2::JUMPTABLE{zdump_env} = \&zdebug_zdump_env;
$zparse2::JUMPTABLE{zdebugsaved_zbefore_actual_process} = $zparse2::JUMPTABLE{zbefore_actual_process};
$zparse2::JUMPTABLE{zbefore_actual_process} = \&zdebug_zbefore_actual_process;
sub zdumpvar { return &{$zparse2::JUMPTABLE{zdumpvar}}( @_ ); }
sub zdump_params { return &{$zparse2::JUMPTABLE{zdump_params}}( @_ ); }
sub zdump_nparams { return &{$zparse2::JUMPTABLE{zdump_nparams}}( @_ ); }
sub zdump_cookies { return &{$zparse2::JUMPTABLE{zdump_cookies}}( @_ ); }
sub zdump_env { return &{$zparse2::JUMPTABLE{zdump_env}}( @_ ); }

$zparse2::unloaddata =
    'undef &zdumpvar; undef &zdebug_zdumpvar;'
    .'undef &zdump_nparams; undef &zdebug_zdump_nparams;'
    .'undef &zdump_cookies; undef &zdebug_zdump_cookies;'
    .'undef &zdump_env; undef &zdebug_zdump_env;'
    .'undef &zdebug_before_actual_process;'
    .'undef &zdump_params; undef &zdebug_zdump_params;';
    
