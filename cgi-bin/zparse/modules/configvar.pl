sub zconfigvar_zconfigvar_modperl
{
    my( $varname, $htvarname, $defval ) = @_;
    zerror "zconfigvar: setting $varname,$htvarname, $defval", 0 ,'debug';
    zerror "zconfigvar: $zparse2::GLOBAL_ERROR", 254, 'error'
        unless zsafeeval "$varname = defined( \$REQ->dir_config( '$htvarname' ) )?\$REQ->dir_config( '$htvarname' ):'$defval' unless defined $varname";
}

sub zconfigvar_zconfigvar_cgi
{
    my( $varname, $htvarname, $defval ) = @_;
    zerror "zconfigvar: setting $varname,$htvarname, $defval", 0 ,'debug';
    zerror "zconfigvar: $zparse2::GLOBAL_ERROR", 254, 'error'
        unless zsafeeval "$varname = '$defval' unless defined( $varname )";
}

sub zconfigvar_zconfigvarbool_modperl
{
    my( $varname, $htvarname, $defval ) = @_;
    zerror "zconfigvarbool: setting $varname,$htvarname, $defval", 0 ,'debug';
    zerror "zconfigvarbool: $zparse2::GLOBAL_ERROR", 254, 'error'
        unless zsafeeval "unless( defined $varname ) { $varname = defined( \$REQ->dir_config( '$htvarname' ) )?\$REQ->dir_config( '$htvarname' ):'$defval'; $varname = ( lc( $varname ) eq 'off')?0:1; }";
}

sub zconfigvar_zconfigvarbool_cgi
{
    my( $varname, $htvarname, $defval ) = @_;
    zerror "zconfigvarbool: setting $varname,$htvarname, $defval", 0 ,'debug';
    zerror "zconfigvarbool: $zparse2::GLOBAL_ERROR", 254, 'error'
        unless zsafeeval "unless( defined $varname ) { $varname = '$defval'; $varname = ( lc( $varname ) eq 'off')?0:1; }";
}

sub zconfigvar_zconfigvarhash_modperl
{
    my( $varname, $htvarname, $defval ) = @_;    
    zerror "zconfigvarhash: setting $varname,$htvarname, $defval", 0 ,'debug';
    $defval =~ s/\'/\\\'/mg;
    zerror "zconfigvarhash: $zparse2::GLOBAL_ERROR", 254, 'error'
        unless zsafeeval "my \$tmp = defined( \$REQ->dir_config( '$htvarname' ) )?\$REQ->dir_config( '$htvarname' ):'$defval';$varname = ( $varname, split(/,/, \$tmp))";
}

sub zconfigvar_zconfigvarhash_cgi
{
    my( $varname, $htvarname, $defval ) = @_;    
    zerror "zconfigvarhash: setting $varname,$htvarname, $defval", 0 ,'debug';
    $defval =~ s/\'/\\\'/mg;
    zerror "zconfigvarhash: $zparse2::GLOBAL_ERROR", 254, 'error'
        unless zsafeeval "my \$tmp = '$defval'; $varname = ( $varname, split(/,/, \$tmp));";
}

sub zconfigvar { return &{$zparse2::JUMPTABLE{zconfigvar}}( @_ ); }
sub zconfigvarbool { return &{$zparse2::JUMPTABLE{zconfigvarbool}}( @_ ); }
sub zconfigvarhash { return &{$zparse2::JUMPTABLE{zconfigvarhash}}( @_ ); }

if( $zparse2::MOD_PERL )
{
    $zparse2::JUMPTABLE{zconfigvar} = \&zconfigvar_zconfigvar_modperl;
    $zparse2::JUMPTABLE{zconfigvarbool} = \&zconfigvar_zconfigvarbool_modperl;
    $zparse2::JUMPTABLE{zconfigvarhash} = \&zconfigvar_zconfigvarhash_modperl;
}
else
{
    $zparse2::JUMPTABLE{zconfigvar} = \&zconfigvar_zconfigvar_cgi;
    $zparse2::JUMPTABLE{zconfigvarbool} = \&zconfigvar_zconfigvarbool_cgi;
    $zparse2::JUMPTABLE{zconfigvarhash} = \&zconfigvar_zconfigvarhash_cgi;
}
