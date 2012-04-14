sub zprintmsgs
{
    zerror "zprintmsgs: !!!obsolete function!!! DON'T USE IT!!!", 126, 'warning';
    goto OUT_HEADERS;
}

sub zreturn
{
    zerror "zreturn: !!!obsolete function!!! DON'T USE IT!!!", 126, 'warning';
    $zparse2::root->{ERRORMSG} = shift;
    die;
}

sub include_perl
{
    my( $files, $root ) = @_;
    zerror "include_perl: !!!obsolete function!!! DON'T USE IT!!!", 126, 'warning';
    zinclude $files, $root, $zparse2::DEFAULT_PERL_MODE;
}

sub zcompat_include
{
    my( $files, $root, $nozmap ) = @_;
    $nozmap = 0 unless defined $nozmap;
    zerror "include: !!!obsolete function!!! DON'T USE IT!!!", 126, 'warning';
    zerror "include: !!!DEFAULT_DATA_MODE!=1!!! BE CAREFUL!!!", 126, 'warning' if $zparse2::DEFAULT_DATA_MODE!=1;
    zinclude $files, $root, $zparse2::DEFAULT_DATA_MODE, $nozmap;
}

sub zdisconnect
{
    zerror "zdisconnect: !!!obsolete function!!! DON'T USE IT!!!", 126, 'warning';
}

sub zclearquerystring
{
    zerror "zclearquerystring: !!!obsolete function!!! DON'T USE IT!!!", 126, 'warning';
}

$zparse2::JUMP_TABLE{include} = \&zcompat_include;
$zparse2::unloaddata = 'undef &zprintmgs; undef &zreturn; undef &include_perl; undef &zcompat_include; undef &zdisconnect; undef &zclearquerystring;';