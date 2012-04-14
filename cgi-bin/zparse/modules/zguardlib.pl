$zparse2::unloaddata = '';

$zparse2::unloaddata .= 'undef &getdbparams;';
sub getdbparams
{
    if( zcheckcookie('zdbd','.*')&&
        zcheckcookie('zdbname','.*')&&
        zcheckcookie('zdbuser','.*')&&
        zcheckcookie('zdbuserpass','.*') )
    {
        $zparse2::DBD = $root->{cookies}->{zdbd};
        $zparse2::DBNAME = $root->{cookies}->{zdbname};
        $zparse2::DBUSER = $root->{cookies}->{zdbuser};
        $zparse2::DBUSERPASS = $root->{cookies}->{zdbuserpass};
    }
    else
    {
	if( ( $zparse2::DBNAME ) && ( $zparse2::DBUSER ) )
	{
            zsendheader 'Set-Cookie: '.zcreatecookie( 'name'=>'back', 'value'=>'', expires=>'-1s' );
            zsendheader 'Set-Cookie: '.zcreatecookie( 'name'=>'forw', 'value'=>'', expires=>'-1s' );
            zsendheader 'Set-Cookie: '.zcreatecookie( 'name'=>'zdbd', 'value'=>"$zparse2::DBD" );
            zsendheader 'Set-Cookie: '.zcreatecookie( 'name'=>'zdbname', 'value'=>"$zparse2::DBNAME" );
            zsendheader 'Set-Cookie: '.zcreatecookie( 'name'=>'zdbuser', 'value'=>"$zparse2::DBUSER" );
            zsendheader 'Set-Cookie: '.zcreatecookie( 'name'=>'zdbuserpass', 'value'=>"$zparse2::DBUSERPASS" );
	}
	else
	{
    	    my $back = $ENV{HTTP_REFERER}?$ENV{HTTP_REFERER}:'';
    	    zsendheader 'Set-Cookie: '.zcreatecookie( 'name'=>'back', 'value'=>$back );
            zsendheader 'Set-Cookie: '.zcreatecookie( 'name'=>'forw', 'value'=>$ENV{REQUEST_URI} );
    	    zredirect '/selectdb.html';
	}
    }
}

$zparse2::unloaddata .= 'undef &adduser;';
sub adduser
{
    my ( $id, $name, $password ) = @_;
    if( $id )
    {
        if( zexecute( "select * from user where usr_id=$id" )->fetch )
        {
            unless( zexecute( "select * from user where usr_name=".zquote($name)." and usr_id<>$id" )->fetch )
            {
		if ( $password )
		{
                	zexecute "update user set usr_name=".zquote($name).", usr_password=".zquote($password)." where usr_id=$id";
		}
		else
		{
			zexecute "update user set usr_name=".zquote($name)." where usr_id=$id";
		}
            }
            else
            {
                $id = 0;
            }
        }
        else
        {
            unless( zexecute( "select * from user where usr_name=".zquote($name) )->fetch )
            {
                zexecute "insert into user values($id,".zquote($name).",".zquote($password).")";
            }
            else
            {
                $id = 0;
            }
        }
    }
    else
    {
        unless( zexecute( "select * from user where usr_name=".zquote($name) )->fetch )
        {
            zexecute "insert into user (usr_name,usr_password) values(".zquote($name).",".zquote($password).")"; 
            $id = zexecute( "select LAST_INSERT_ID();" )->fetch->[0];
        }
        else
        {
            $id = 0;
        }
    }
    return $id;
}

$zparse2::unloaddata .= 'undef &deluser;';
sub deluser
{
    my $id = shift;
    zexecute "delete from user where usr_id=$id";
    zexecute "delete from user_right where usr_id=$id";
    zexecute "delete from user_profile where usr_id=$id";
}

$zparse2::unloaddata .= 'undef &addright;';
sub addright
{
    my( $id, $parentid, $name, $longname, $default, $multiright ) = @_;
    if( $id )
    {
        if( zexecute( "select * from zright where rig_id=$id" )->fetch )
        {
            unless( zexecute( "select * from zright where rig_name=".zquote($name)." and rig_id<>$id and rig_parentid=$parentid" )->fetch )
            {
                zexecute "update zright set rig_parentid=$parentid,rig_name=".zquote($name)
                    .",rig_longname=".zquote($longname).",rig_default=$default,rig_multiright=".zquote($multiright)." where rig_id=$id";
            }
            else
            {
                $id = 0;
            }
        }
        else
        {
            unless( zexecute( "select * from zright where rig_name=".zquote($name)." and rig_parentid=$parentid" )->fetch )
            {
                zexecute "insert into right(rig_parentid,rig_name,rig_longname,rig_default,rig_multiright) "
                    ."values($parentid,".zquote($name).",".zquote($longname).",$default,".zquote($multiright).")";
            }
            else
            {
                $id = 0;
            }
        }
    }
    else
    {
        unless( zexecute( "select * from zright where rig_name=".zquote($name)." and rig_parentid=$parentid" )->fetch )
        {
            zexecute "insert into zright values($id,$parentid,".zquote($name).",".zquote($longname).",$default,".zquote($multiright).")";
            $id = zexecute( "select LAST_INSERT_ID();" )->fetch->[0];
        }
        else
        {
            $id = 0;
        }
    }
    return $id;
}

$zparse2::unloaddata .= 'undef &delright;';
sub delright
{
    my $id = shift;
    zexecute "delete from zright where rig_id=$id";
    zexecute "delete from user_right where rig_id=$id";
    zexecute "delete from profile_right where rig_id=$id";
    my $result = zexecute "select * from zright where rig_parentid=$id";
    while( my $datahash = $result->fetchrow_hashref )
    {
        delright( $datahash->{rig_id} );
    }
}

$zparse2::unloaddata .= 'undef &addprofile;';
sub addprofile
{
    my( $id, $name, $longname ) = @_;
    if( $id )
    {
        if( zexecute( "select * from profile where prf_id=$id" )->fetch )
        {
            unless( zexecute( "select * from profile where prf_name=".zquote($name)." and prf_id<>$id" )->fetch )
            {
                zexecute "update profile set prf_name=".zquote($name).",prf_longname=".zquote($longname)." where prf_id=$id";
            }
            else
            {
                $id = 0;
            }
        }
        else
        {
            unless( zexecute( "select * from profile where prf_name=".zquote($name) )->fetch )
            {
                zexecute "insert into profile values($id,".zquote($name).",".zquote($longname).")";
            }
            else
            {
                $id = 0;
            }
        }
    }
    else
    {
        unless( zexecute( "select * from profile where prf_name=".zquote($name) )->fetch )
        {
            zexecute "insert into profile (prf_name,prf_longname) values(".zquote($name).",".zquote($longname).")";
            $id = zexecute( "select LAST_INSERT_ID();" )->fetch->[0];
        }
        else
        {
            $id = 0;
        }
    }
    return $id;
}

$zparse2::unloaddata .= 'undef &delprofile;';
sub delprofile
{
    my $id = shift;
    zexecute "delete from profile where prf_id=$id";
    zexecute "delete from profile_right where prf_id=$id";
    zexecute "delete from user_profile where prf_id=$id";
}

$zparse2::unloaddata .= 'undef &adduserright;';
sub adduserright
{
    my ( $usr_id, $rig_id, $rig_addid, $value ) = @_;
    if( zexecute( "select * from user_right where usr_id=$usr_id and rig_id=$rig_id and rig_addid=".zquote($rig_addid) )->fetch )
    {
        zexecute "update user_right set ur_value=$value where usr_id=$usr_id and rig_id=$rig_id and rig_addid=".zquote($rig_addid);
    }
    else
    {
        zexecute "insert into user_right values ($rig_id,".zquote($rig_addid).",$usr_id,$value)";
    }
    if( $value )
    {
        my $datahash = zexecute( "select * from zright where rig_id=$rig_id" )->fetchrow_hashref;
        if( $datahash )
        {
            my $rig_parentid = $datahash->{rig_parentid};
            my $rig_multiright = $datahash->{rig_multiright};
            if( $rig_multiright )
            {
                my $result = zexecute $rig_multiright;
                while( my $datahash = $result->fetchrow_hashref )
                {
                    my $mlt_addid=$datahash->{mlt_addid};
                    if( $rig_addid =~ /^(.*)$mlt_addid$/ )
                    {
                        $rig_addid = $1;                        
                        adduserright( $usr_id, $rig_parentid, $rig_addid, $value );
                        last;
                    }
                }
            }
            else
            {
                adduserright( $usr_id, $rig_parentid, $rig_addid, $value );
            }
        }
    }
}

$zparse2::unloaddata .= 'undef &deluserright;';
sub deluserright
{
    my ( $usr_id, $rig_id, $rig_addid ) = @_;
    zexecute "delete from user_right where usr_id=$usr_id and rig_id=$rig_id and rig_addid=".zquote($rig_addid);
}

$zparse2::unloaddata .= 'undef &addprofileright;';
sub addprofileright
{
    my ( $prf_id, $rig_id, $rig_addid, $value ) = @_;
    if( zexecute( "select * from profile_right where prf_id=$prf_id and rig_id=$rig_id and rig_addid=".zquote($rig_addid) )->fetch )
    {
        zexecute "update profile_right set pr_value=$value where prf_id=$prf_id and rig_id=$rig_id and rig_addid=".zquote($rig_addid);
    }
    else
    {
        zexecute "insert into profile_right values ($rig_id,".zquote($rig_addid).",$prf_id,$value)";
    }
    if( $value )
    {
        my $datahash = zexecute( "select * from zright where rig_id=$rig_id" )->fetchrow_hashref;
        if( $datahash )
        {
            my $rig_parentid = $datahash->{rig_parentid};
            my $rig_multiright = $datahash->{rig_multiright};
            if( $rig_multiright )
            {
                my $result = zexecute $rig_multiright;
                while( my $datahash = $result->fetchrow_hashref )
                {
                    my $mlt_addid=$datahash->{mlt_addid};
                    if( $rig_addid =~ /^(.*)$mlt_addid$/ )
                    {
                        $rig_addid = $1;                        
                        addprofileright( $prf_id, $rig_parentid, $rig_addid, $value );
                        last;
                    }
                }
            }
            else
            {
                addprofileright( $prf_id, $rig_parentid, $rig_addid, $value );
            }
        }
    }
}

$zparse2::unloaddata .= 'undef &delprofileright;';
sub delprofileright
{
    my ( $prf_id, $rig_id, $rig_addid ) = @_;
    zexecute "delete from profile_right where prf_id=$prf_id and rig_id=$rig_id and rig_addid=".zquote($rig_addid);
}

$zparse2::unloaddata .= 'undef &adduserprofile;';
sub adduserprofile
{
    my ( $prf_id, $usr_id ) = @_;
    unless( zexecute( "select * from user_profile where prf_id=$prf_id and usr_id=$usr_id" )->fetch )
    {
        zexecute "insert into user_profile values ($usr_id,$prf_id)";
    }
}

$zparse2::unloaddata .= 'undef &deluserprofile;';
sub deluserprofile
{
    my ( $prf_id, $usr_id ) = @_;
    zexecute "delete from user_profile where prf_id=$prf_id and usr_id=$usr_id";
}
