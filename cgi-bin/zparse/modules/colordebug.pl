sub zcolordebug_zoutdebug
{
    $zparse2::messages =~ s/(debug:)/\<font color=\"green\"\>$1\<\/font\>/mg;
    $zparse2::messages =~ s/(warning:)([^\n]*)\n/\<font color=\"magenta\"\>$1\<\/font\>\<font color=\"blueviolet\"\>$2\<\/font\>/mg;
    $zparse2::messages =~ s/(error:)([^\n]*)\n/\<font color=\"red\"\>$1\<\/font\>\<font color=\"orangered\"\>$2\<\/font\>/mg;
    $zparse2::messages =~ s/(notfound:)([^\n]*)\n/\<font color=\"red\"\>$1\<\/font\>\<font color=\"orangered\"\>$2\<\/font\>/mg;
    $zparse2::messages =~ s/(usererror:)([^\n]*)\n/\<font color=\"red\"\>$1\<\/font\>\<font color=\"orangered\"\>$2\<\/font\>/mg;
    $zparse2::messages =~ s/(zmap:)\s+(\$matched=0)([^\n]*)\n/\<font color=\"Silver\"\>$1\<\/font\>\<font color=\"Red\"\>$2$3\<\/font\>/mg;
    $zparse2::messages =~ s/(zmap:)\s+(\$matched=1)([^\n]*)\n/\<font color=\"Silver\"\>$1\<\/font\>\<font color=\"Blue\"\>$2$3\<\/font\>/mg;
    
    return &{$zparse2::JUMPTABLE{zdebugsaved_zoutdebug}}( @_ );
}

$zparse2::JUMPTABLE{zdebugsaved_zoutdebug} = $zparse2::JUMPTABLE{zoutdebug};
$zparse2::JUMPTABLE{zoutdebug} = \&zcolordebug_zoutdebug;

$zparse2::unloaddata =
    'undef &zcolordebug_zoutdebug;';
