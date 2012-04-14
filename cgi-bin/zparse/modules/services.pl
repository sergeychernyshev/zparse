sub zclearoutput { return &{$zparse2::JUMPTABLE{zclearoutput}}( @_ ); }
sub zredirect { return &{$zparse2::JUMPTABLE{zredirect}}( @_ ); }
sub zexpires { return &{$zparse2::JUMPTABLE{zexpires}}( @_ ); }
sub zcreatecookie { return &{$zparse2::JUMPTABLE{zcreatecookie}}( @_ ); }
sub zescape { return &{$zparse2::JUMPTABLE{zescape}}( @_ ); }
sub zunescape { return &{$zparse2::JUMPTABLE{zunescape}}( @_ ); }
sub zcheckparam { return &{$zparse2::JUMPTABLE{zcheckparam}}( @_ ); }
sub zcheckparam2 { return &{$zparse2::JUMPTABLE{zcheckparam2}}( @_ ); }
sub zcheckcookie { return &{$zparse2::JUMPTABLE{zcheckcookie}}( @_ ); }
sub zinitcookies { return &{$zparse2::JUMPTABLE{zinitcookies}}( @_ ); }
sub zinitparams { return &{$zparse2::JUMPTABLE{zinitparams}}( @_ ); }


sub zservices_zclearoutput
{
    untie *STDOUT;
    tie *STDOUT, 'zparse2';
}

sub zservices_zredirect
{
    my $url=shift;
    #zerror "zredirect param: \"$url\"", 0, 'debug';

    $url='./' if ($url eq '');
    #zerror "zredirect param2: \"$url\"", 0, 'debug';

    if ($url=~/\?/)
    {
        $url.='&___drop_redirect='.time().$$;
    }
    else
    {   
        $url.='?___drop_redirect='.time().$$;
    }
    zsendheader "Location: $url";
    $zparse2::RETURNCODE=301;

    zerror ('zredirect: '.$url,0,'debug');

    goto OUT_HEADERS;
#    my $url=shift;
#    if ($url=~/\:\/\//)
#    {
#       zsendheader 'Location: '.$url;
#    }
#    else
#    {   
#       my $location='http://'.$ENV{SERVER_NAME};
#       $location.=$ENV{SERVER_PORT} if ($ENV{SERVER_PORT} != 80);
#       $location.=$url;
#       zsendheader 'Location: '.$location;
#    }
#
#    $zparse2::RETURNCODE=301;
#    goto OUT_HEADERS;
}

sub zservices_zexpires
{
    my $exp = shift;
    if( defined $exp )
    {                
        unless( $exp =~ /\w+,\s+\d+-\w+-\d+\s+\d+:\d+:\d+\s+GMT/)
        {
            my @time = localtime;
            unless( $exp =~ /now/ )
            {
                $time[0]+=$1 if $exp =~ /((\+|\-)\d+)s/;
                $time[1]+=$1 if $exp =~ /((\+|\-)\d+)m/;
                $time[2]+=$1 if $exp =~ /((\+|\-)\d+)h/;
                $time[3]+=$1 if $exp =~ /((\+|\-)\d+)d/;
                $time[4]+=$1 if $exp =~ /((\+|\-)\d+)M/;
                $time[5]+=$1 if $exp =~ /((\+|\-)\d+)y/;
            }            
            my @t = gmtime( POSIX::mktime( @time ) ); $t[8]=1;
            my $loc = POSIX::setlocale( &POSIX::LC_TIME, "C" );
            $exp = POSIX::strftime( "%A, %d-%b-%Y %H:%M:%S GMT", @t );
            POSIX::setlocale( &POSIX::LC_TIME, $loc );
        }    
    }
    return $exp;
}

sub zservices_zcreatecookie
{
    my %params = (@_);
    zerror 'zcreatecookie: name must be defined', 254, 'error' unless defined $params{name};
    zerror 'zcreatecookie: value must be defined', 254, 'error' unless defined $params{value};
    my $cookie = zescape( $params{name} ).'='.zescape( $params{value} ).';';
    $cookie.='domain='.$params{domain}.';' if defined $params{domain};
    $params{path}='/' unless defined $params{path};
    $cookie.='path='.$params{path}.';';
    $cookie.='expires='.zexpires( $params{expires} ).';' if defined $params{expires};
    zerror "zcreatecookie: $cookie", 0, 'debug';
    return $cookie;
}

sub zservices_zescape
{
    my $text = shift;
    return undef unless defined $text;
    $text =~ s/([^a-zA-Z0-9_.-])/uc sprintf("%%%02x",ord($1))/eg;
    return $text;
}

sub zservices_zunescape
{
    my $text = shift;
    return undef unless defined $text;
    $text =~ tr/+/ /;
    $text =~ s/%([0-9a-fA-F]{2})/pack("c",hex($1))/ge;
    return $text;
}

sub zservices_readbuf
{
    my($rbuffer, $rcontent_length, $bytes) = @_;
    my $bytesread = 0;
    if( $$rcontent_length>0 )
    {	
        my $bytestoread = $bytes-length($$rbuffer);
        $bytestoread = $$rcontent_length if $$rcontent_length<$bytes;
        if( $zparse2::MOD_PERL ) 
	{ 
	    $bytesread = $REQ->read( $$rbuffer, $bytestoread, length($$rbuffer) ); 
	}
        else 
	{ 
	    $bytesread = read( STDIN, $$rbuffer, $bytestoread, length($$rbuffer) ); 
	}
        $$rcontent_length -= $bytesread;
        if( $bytesread==0 )
        {
            zerror "server closed socket (client aborted?).\n", 254, 'error' 
                if $zparse2::zero_loop_counter++>$zparse2::SPIN_LOOP_MAX;
        }
        else { $zparse2::zero_loop_counter=0; }
    }
    return ($$rcontent_length>0)||($bytesread>0)||(length($$rbuffer)>0);
}

sub zservices_zinitparams
{
    return if $zparse2::PARAMS_PARSED;
    $zparse2::PARAMS_PARSED=1;
    my $query_string;
    $zparse2::PARAM_BUFFER_SIZE = 16384 unless defined $zparse2::PARAM_BUFFER_SIZE;
    $zparse2::SPIN_LOOP_MAX = 100 unless defined $zparse2::SPIN_LOOP_MAX;
    $zparse2::TMP_DIRECTORY = '/tmp/' unless defined $zparse2::TMP_DIRECTORY;
    $zparse2::TMP_MAXTRIES = 100 unless defined $zparse2::TMP_MAXTRIES;
    $zparse2::TMP_SEQUENCE = 0 unless defined $zparse2::TMP_SEQUENCE;
    $zparse2::MAX_HEADERS_SIZE = 16384 unless defined $zparse2::MAX_HEADERS_SIZE;
    my ($content_length,$method, $args, $content_type);
    if( $zparse2::MOD_PERL )
    {
        $content_length = defined( $REQ->header_in('Content-length') ) ? $REQ->header_in('Content-length') : 0;
        $method = $REQ->method;
        $args = $ENV{QUERY_STRING};
        $content_type = $REQ->header_in('Content-type');
    }
    else
    {
        $content_length = defined( $ENV{CONTENT_LENGTH} ) ? $ENV{CONTENT_LENGTH} : 0;
        $method = $ENV{REQUEST_METHOD};
        $args = $ENV{QUERY_STRING};
        $content_type = $ENV{CONTENT_TYPE};
    }
    if( $method =~ /^(GET|HEAD)$/ )
    {
        $query_string = $args;
    }
    elsif( $method eq 'POST' )
    {
        if( $content_type =~ m|^multipart/form-data| )
        {
            my ($boundary) = $content_type =~ /boundary=\"?([^\";,]+)\"?/;
            $boundary = '--'.$boundary;
            my $buffer='';
            while( zservices_readbuf( \$buffer, \$content_length, $zparse2::PARAM_BUFFER_SIZE ) )
            {
                my $start = index( $buffer, $boundary.'--' );
                last if $start==0;
                $start = index( $buffer, $boundary );
                zerror "zinitparams: POST boundary expected [buffer = $buffer]", 254, 'error' if $start != 0;
                substr( $buffer, 0, length($boundary)+2 ) = '';  # cut boundary

                #read headers;
                my $headers = '';
                $start = index( $buffer, "\015\012\015\012" );
                while( $start < 0 )
                {
                    my $cutlen = length( $buffer )/2;
                    $headers .= substr( $buffer, 0, $cutlen ); substr( $buffer, 0, $cutlen ) = '';
                    zerror "zinitparams: POST more data expected [buffer = $buffer]", 254, 'debug'
                        unless zservices_readbuf( \$buffer, \$content_length, $zparse2::PARAM_BUFFER_SIZE );
                    $start = index( $buffer, "\015\012\015\012" );
                    #TODO: protect against large headers
                }
                $headers .= substr( $buffer, 0, $start+2 );
                substr( $buffer, 0, $start+4 ) = ''; # now points to data
                #parse headers
                my %headers = ();
                $headers =~ s/\015\012\s+/ /og;
                my $token = '[-\w!\#$%&\'*+.^_\`|{}~]';
                while ($headers=~/($token+):\s+([^\015\012]*)/mgox) 
                {
	            my ($field_name,$field_value) = ($1,$2);
	            $field_name =~ s/\b(\w)/uc($1)/eg; 
	            $headers{$field_name}=$field_value;
                }

                my ($param) = $headers{'Content-Disposition'} =~ /name=\"?([^\";]*)\"?/;
                my ($filename) = $headers{'Content-Disposition'} =~ /filename=\"?([^\";]*)\"?/;
                my $value = '';
                if( $filename )
                {
                    #save uploaded file
                    my $tmpfilename = '';
                    my $timestamp = time;
                    for( my $i=0; $i <$zparse2::TMP_MAXTRIES; $i++ )
                    {
                        $tmpfilename = sprintf "$zparse2::TMP_DIRECTORY/zp2_%d_%d_%d.tmp", $$, $timestamp, $zparse2::TMP_SEQUENCE++;
                        last unless -f $tmpfilename;
                    }
                            
                    zerror 'cannot save uploaded data to temporary file', 254, 'error' unless open FILE, ">$tmpfilename";
                    push @zparse2::tmpfiles, "$tmpfilename";
                    $start = index( $buffer, $boundary );
                    while( $start < 0 )
                    {
                        my $cutlen = length( $buffer )/2;
                        $value = substr( $buffer, 0, $cutlen ); substr( $buffer, 0, $cutlen ) = '';
                        print FILE $value;
			
                        zerror 'malformed POST data'." buffer = $buffer", 254, 'debug'
                            unless zservices_readbuf( \$buffer, \$content_length, $zparse2::PARAM_BUFFER_SIZE );
                        $start = index( $buffer, $boundary );
                    }                    
                    $value = substr( $buffer, 0, $start - 2 );
                    print FILE $value;
                    substr( $buffer, 0, $start ) = '';
                    close FILE;
                    if( defined $root->{nparams}->{$param} )
                    {
                        if( $root->{nparams}->{$param}->{type} eq 'file' )
                        {
                            $root->{nparams}->{$param}->{type}='filearray';
                            $root->{nparams}->{$param}->{n} = 1;
                            $root->{nparams}->{$param}->{1}->{headers} = $root->{nparams}->{$param}->{headers};
                            $root->{nparams}->{$param}->{1}->{filename} = $root->{nparams}->{$param}->{filename};
                            $root->{nparams}->{$param}->{1}->{tmpfilename} = $root->{nparams}->{$param}->{tmpfilename};
                            undef $root->{nparams}->{$param}->{headers};
                            undef $root->{nparams}->{$param}->{filename};
                            undef $root->{nparams}->{$param}->{tmpfilename};
                        }
                        elsif( $root->{nparams}->{$param}->{type} ne 'filearray' ) { zerror "file and param with same name '$param'", 254, 'error'; }
                        my $n = ++$root->{nparams}->{$param}->{n};
                        $root->{nparams}->{$param}->{$n}->{headers} = { %headers };
                        $root->{nparams}->{$param}->{$n}->{filename} = $filename;
                        $root->{nparams}->{$param}->{$n}->{tmpfilename} = $tmpfilename;
                    }
                    else
                    {
                        $root->{nparams}->{$param}->{headers} = { %headers };
                        $root->{nparams}->{$param}->{type}='file';
                        $root->{nparams}->{$param}->{name}=$param;
                        $root->{nparams}->{$param}->{filename}=$filename;
                        $root->{nparams}->{$param}->{tmpfilename}=$tmpfilename;
                    }
                }
                else
                {
                    #load parameter
                    $start = index( $buffer, $boundary );
                    while( $start < 0 )
                    {
                        my $cutlen = length( $buffer )/2;
                        $value .= substr( $buffer, 0, $cutlen ); substr( $buffer, 0, $cutlen ) = '';
                        zerror 'malformed POST data'." buffer = $buffer", 254, 'debug'
                            unless zservices_readbuf( \$buffer, \$content_length, $zparse2::PARAM_BUFFER_SIZE );
                        $start = index( $buffer, $boundary );
                        #TODO: protect against large parameter
                    }
                    $value .= substr( $buffer, 0, $start - 2 );
                    substr( $buffer, 0, $start ) = '';
                    if( defined $root->{nparams}->{$param} )
                    {
                        if( $root->{nparams}->{$param}->{type} eq 'simple' )
                        {
                            $root->{nparams}->{$param}->{type}='array';
                            $root->{nparams}->{$param}->{n} = 1;
                            $root->{nparams}->{$param}->{1}->{headers} = $root->{nparams}->{$param}->{headers};
                            $root->{nparams}->{$param}->{1}->{value} = $root->{nparams}->{$param}->{value};
                            undef $root->{nparams}->{$param}->{headers};
                            undef $root->{nparams}->{$param}->{value};
                        }
                        elsif( $root->{nparams}->{$param}->{type}ne 'array' ) { zerror "file and param with same name '$param'", 254, 'error'; }
                        my $n = ++$root->{nparams}->{$param}->{n};
                        $root->{nparams}->{$param}->{$n}->{headers} = { %headers };
                        $root->{nparams}->{$param}->{$n}->{value} = $value;
                    }
                    else
                    {
                        $root->{nparams}->{$param}->{headers} = { %headers };
                        $root->{nparams}->{$param}->{type}='simple';
                        $root->{nparams}->{$param}->{name}=$param;
                        $root->{nparams}->{$param}->{value}=$value;
                    }
                }
                
            }
            $query_string.='&'.$args;
        }
        else
        {
            #TODO: protect against large headers
            if( $zparse2::MOD_PERL ) { $REQ->read( $query_string, $content_length ); }
            else { read( STDIN, $query_string, $content_length ); }
            $query_string.='&'.$args;
        }
    }
    if( $query_string )
    {
        foreach my $pair ( split /&/, $query_string )
        {
            next unless $pair;
            my ($param,$value) = split /=/, $pair, 2;
            $param = zunescape $param;
            $value = zunescape $value;
            if( defined $root->{nparams}->{$param} )
            {
                if( $root->{nparams}->{$param}->{type} eq 'simple' )
                {
                    $root->{nparams}->{$param}->{type}='array';
                    $root->{nparams}->{$param}->{n} = 1;
                    $root->{nparams}->{$param}->{1}->{headers} = $root->{nparams}->{$param}->{headers};
                    $root->{nparams}->{$param}->{1}->{value} = $root->{nparams}->{$param}->{value};
                    undef $root->{nparams}->{$param}->{headers};
                    undef $root->{nparams}->{$param}->{value};
                }
                elsif( $root->{nparams}->{$param}->{type}ne 'array' ) { zerror "file and param with same name '$param'", 254, 'error'; }
                my $n = ++$root->{nparams}->{$param}->{n};
                $root->{nparams}->{$param}->{$n}->{value} = $value;
            }
            else
            {
                $root->{nparams}->{$param}->{type}='simple';
                $root->{nparams}->{$param}->{name}=$param;
                $root->{nparams}->{$param}->{value}=$value;
            }
        }
    }
#    zerror "zinitparams: query_string = $query_string", 0, 'debug';
#    zerror "zinitparams: args = $args", 0, 'debug';
#    zdump_nparams() if defined &zdump_nparams;
}

sub zservices_zcheck_message
{
    my( $errtext, $param_flags, $user_message )=@_;
    if( $param_flags ne "ignore" )
    {
        if( defined $user_message ) { zerror $user_message, 254, 'usererror'; }
        else { zerror $errtext, 254, 'error'; }
    }
}

sub zservices_zcheckparam
{
    my( $param_name, $param_mask, $param_array, $param_flags, $user_message ) = @_;
    zservices_zinitparams;
    zservices_zcheck_message "zcheckparam: undefined parameter value ( $param_name )", $param_flags, $user_message
        unless defined $root->{nparams}->{$param_name};
    return unless defined $root->{nparams}->{$param_name};
    if( $param_array )
    {
        if( $root->{nparams}->{$param_name}->{type} eq 'array' )
        {
            for( my $i=1; $i<= $root->{nparams}->{$param_name}->{n}; $i++ )
            {
                my $param_value = $root->{nparams}->{$param_name}->{$i}->{value};
		if( $param_value =~/$param_mask/ )
		{
		    $root->{params}->{$param_name}->{$i}=$param_value;
		}
		else
		{
            	    zservices_zcheck_message "zcheckparam: invalid parameter value [$param_name = $param_value]", $param_flags, $user_message;
		}
        	zerror "zcheckparam: \$param_name[$i] = ".$root->{params}->{$param_name}->{$i}, 0, 'debug';
            }
        } elsif( $root->{nparams}->{$param_name}->{type} eq 'simple' ) {
            my $param_value = $root->{nparams}->{$param_name}->{value};
	    if( $param_value =~/$param_mask/ )
	    {
        	$root->{params}->{$param_name}->{1}=$param_value;
	    }
	    else
	    {
        	zservices_zcheck_message "zcheckparam: invalid parameter value [$param_name = $param_value]", $param_flags, $user_message;
            }
	    zerror "zcheckparam: \$param_name[1] = ".$root->{params}->{$param_name}->{1}, 0, 'debug';
        } else { zerror "zcheckparam: cannot deal with file parameter $param_name. use zcheckparam2", 0, 'error'; }
    } else {
        if( $root->{nparams}->{$param_name}->{type} eq 'simple' )
        {
            my $param_value = $root->{nparams}->{$param_name}->{value};
	    if( $param_value =~/$param_mask/ )
	    {
		$root->{params}->{$param_name}=$param_value;
	    }
	    else
	    {
        	zservices_zcheck_message "zcheckparam: invalid parameter value [$param_name = $param_value]", $param_flags, $user_message;
	    }
            zerror( "zcheckparam: $param_name = ".$root->{params}->{$param_name}, 0, 'debug' );
        } elsif( $root->{nparams}->{$param_name}->{type} eq 'array' ) {
            my $param_value = $root->{nparams}->{$param_name}->{1}->{value};
	    if( $param_value =~/$param_mask/ )
	    {
		$root->{params}->{$param_name}=$param_value;
	    }
	    else
	    {
        	zservices_zcheck_message "zcheckparam: invalid parameter value [$param_name = $param_value]", $param_flags, $user_message;
	    }
            zerror( "zcheckparam: $param_name = ".$root->{params}->{$param_name}, 0, 'debug' );
        } else { zerror "zcheckparam: cannot deal with file parameter $param_name. use zcheckparam2", 0, 'error'; }
    }
}

sub zservices_zcheckparam2
{
    my($param_name,$param_mask,$param_type,$usermessage,$loglevel,$flag) = @_;
    zservices_zinitparams;
    if( defined $root->{nparams}->{$param_name} )
    {    
        if( ($root->{nparams}->{$param_name}->{type} eq 'simple') && ($param_type eq 'array') )
        {
            $root->{nparams}->{$param_name}->{type} = 'array';
            $root->{nparams}->{$param_name}->{n} = 1;
            $root->{nparams}->{$param_name}->{1}->{headers} = $root->{nparams}->{$param_name}->{headers};
            $root->{nparams}->{$param_name}->{1}->{value} = $root->{nparams}->{$param_name}->{value};
            undef $root->{nparams}->{$param_name}->{headers};
            undef $root->{nparams}->{$param_name}->{value};            
        } elsif( ($root->{nparams}->{$param_name}->{type} eq 'array') && ($param_type eq 'simple') ) {
            $root->{nparams}->{$param_name}->{type} = 'simple';
            $root->{nparams}->{$param_name}->{headers} = $root->{nparams}->{$param_name}->{1}->{headers};
            $root->{nparams}->{$param_name}->{value} = $root->{nparams}->{$param_name}->{1}->{value};
            for( my $i=1; $i <= $root->{nparams}->{$param_name}->{n}; $i++ )
                { undef $root->{nparams}->{$param_name}->{$i}; }
            undef $root->{nparams}->{$param_name}->{n};
        } elsif( ($root->{nparams}->{$param_name}->{type} eq 'file') && ($param_type eq 'filearray') ) {
            $root->{nparams}->{$param_name}->{type} = 'filearray';
            $root->{nparams}->{$param_name}->{n} = 1;
            $root->{nparams}->{$param_name}->{1}->{headers} = $root->{nparams}->{$param_name}->{headers};
            $root->{nparams}->{$param_name}->{1}->{filename} = $root->{nparams}->{$param_name}->{filename};
            $root->{nparams}->{$param_name}->{1}->{tmpfilename} = $root->{nparams}->{$param_name}->{tmpfilename};
            undef $root->{nparams}->{$param_name}->{headers};
            undef $root->{nparams}->{$param_name}->{filename};
            undef $root->{nparams}->{$param_name}->{tmpfilename};
        } elsif( ($root->{nparams}->{$param_name}->{type} eq 'filearray') && ($param_type eq 'file') ) {
            $root->{nparams}->{$param_name}->{type} = 'simple';
            $root->{nparams}->{$param_name}->{headers} = $root->{nparams}->{$param_name}->{1}->{headers};
            $root->{nparams}->{$param_name}->{filename} = $root->{nparams}->{$param_name}->{1}->{filename};
            $root->{nparams}->{$param_name}->{tmpfilename} = $root->{nparams}->{$param_name}->{1}->{tmpfilename};
            for( my $i=1; $i <= $root->{nparams}->{$param_name}->{n}; $i++ )
                { undef $root->{nparams}->{$param_name}->{$i}; }
            undef $root->{nparams}->{$param_name}->{n};        
        }
        if( $root->{nparams}->{$param_name}->{type} eq $param_type )
        {
            if( $root->{nparams}->{$param_name}->{type} eq 'simple' )
            {
                return 1 if $root->{nparams}->{$param_name}->{value} =~ /$param_mask/;
            } elsif( $root->{nparams}->{$param_name}->{type} eq 'array' ) {
                my $rv = 1;
                for( my $i=1; $i <= $root->{nparams}->{$param_name}->{n}; $i++ )
                    { $rv = 0 unless $root->{nparams}->{$param_name}->{$i}->{value} =~ /$param_mask/; }
                return 1 if $rv;
            } elsif( $root->{nparams}->{$param_name}->{type} eq 'file' ) {
                return 1 if $root->{nparams}->{$param_name}->{filename} =~ /$param_mask/;
            } elsif( $root->{nparams}->{$param_name}->{type} eq 'filearray' ) {
                my $rv = 1;
                for( my $i=1; $i <= $root->{nparams}->{$param_name}->{n}; $i++ )
                    { $rv = 0 unless $root->{nparams}->{$param_name}->{$i}->{filename} =~ /$param_mask/; }
                return 1 if $rv;            
            }
        }
    }
    $loglevel = 254 unless defined $loglevel;
    $flag = 'error' unless defined $flag;
    zerror "zcheckparam2: $usermessage", $loglevel, $flag if defined $usermessage;
    return 0;
}

sub zservices_zinitcookies
{
    return if $zparse2::COOKIES_PARSED;
    $zparse2::COOKIES_PARSED=1;
    my $cookie = $ENV{HTTP_COOKIE} || $ENV{COOKIE};
    return unless $cookie;
    foreach my $pair ( split /;\ /, $cookie )
    {
        my($key,$value) = split( /=/, $pair, 2 );
        $key = zunescape $key;
        $value = zunescape $value;
        $root->{cookies}->{$key} = $value unless defined $root->{cookies}->{$key};
    }
}

sub zservices_zcheckcookie
{
    my ($name, $mask, $usermessage, $loglevel, $flag )= @_;
    zservices_zinitcookies;
    return 1 if (defined $root->{cookies}->{$name})&&($root->{cookies}->{$name} =~ /$mask/);
    $loglevel = 254 unless defined $loglevel;
    $flag = 'error' unless defined $flag;
    zerror "zcheckcookie: $usermessage", $loglevel, $flag if defined $usermessage;
    return 0;
}

sub zservices_zbefore_actual_process
{
    $zparse2::COOKIES_PARSED=0;
    $zparse2::PARAMS_PARSED=0;
    return &{$zparse2::JUMPTABLE{zservicessaved_zbefore_actual_process}}( @_ );
}

sub zservices_zafter_actual_process
{
    $zparse2::COOKIES_PARSED=0;
    $zparse2::PARAMS_PARSED=0;
    foreach my $tmpfile ( @zparse2::tmpfiles )
    {
        unlink $tmpfile if -f $tmpfile;
    }
    undef @zparse2::tmpfiles;
    return &{$zparse2::JUMPTABLE{zservicessaved_zafter_actual_process}}( @_ );
}

$zparse2::JUMPTABLE{zclearoutput} = \&zservices_zclearoutput;
$zparse2::JUMPTABLE{zredirect} = \&zservices_zredirect;
$zparse2::JUMPTABLE{zexpires} = \&zservices_zexpires;
$zparse2::JUMPTABLE{zcreatecookie} = \&zservices_zcreatecookie;
$zparse2::JUMPTABLE{zescape} = \&zservices_zescape;
$zparse2::JUMPTABLE{zunescape} = \&zservices_zunescape;
$zparse2::JUMPTABLE{zcheckparam} = \&zservices_zcheckparam;
$zparse2::JUMPTABLE{zcheckparam2} = \&zservices_zcheckparam2;
$zparse2::JUMPTABLE{zservicessaved_zbefore_actual_process} = $zparse2::JUMPTABLE{zbefore_actual_process};
$zparse2::JUMPTABLE{zbefore_actual_process} = \&zservices_zbefore_actual_process;
$zparse2::JUMPTABLE{zservicessaved_zafter_actual_process} = $zparse2::JUMPTABLE{zafter_actual_process};
$zparse2::JUMPTABLE{zafter_actual_process} = \&zservices_zafter_actual_process;
$zparse2::JUMPTABLE{zcheckcookie} = \&zservices_zcheckcookie;
$zparse2::JUMPTABLE{zinitcookies} = \&zservices_zinitcookies;
$zparse2::JUMPTABLE{zinitparams} = \&zservices_zinitparams;


$zparse2::unloaddata = 
    'undef &zclearoutput; undef &zservices_zclearoutput; undef &zredirect;'
    .'undef &zservices_zredirect; undef &zexpires; undef &zservices_zexpires;'
    .'undef &zcreatecookie; undef &zservices_zcreatecookie; undef &zescape;'
    .'undef &zservices_zescape; undef &zunescape; undef &zservices_zunescape;'
    .'undef &zcheckparam; undef &zservices_zcheckparam; undef &zservices_zcheckparam2;'
    .'undef &zservices_zcheck_message; undef &zservices_readbuf; undef &zservices_zinitparams;'
    .'undef &zcheckparam2;'
    .'undef &zservices_zinitcookies; undef &zcheckcookie; undef &zservices_zcheckcookie;'
    .'undef &zinitcookies; undef &zinitparams;'
    .'undef &zservices_zbefore_actual_process; undef &zservices_zafter_actual_process;';
