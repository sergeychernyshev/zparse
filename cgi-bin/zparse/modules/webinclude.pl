sub zcopyhash
{
    my $f = shift;
    if( ref $f eq 'HASH' )
    {
        my %tmp = map { $_ => zcopyhash( $f->{$_} ) } keys %$f;
        return \%tmp;
    }
    elsif( ref $f eq 'ARRAY' )
    {
        my @tmp = map { zcopyhash( $_ ) } @$f;
        return \@tmp;
    }
    else
    {
        return  $f;
    }
}

sub minizinitparams
{
    my ( $query_string ) = @_;
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
}

sub minizinitcookies
{
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

sub zwi_webinclude
{    
    my ( $uri, $do_copy_hash )= @_;
    $do_copy_hash = 0 unless defined ($do_copy_hash);

	zerror "webincluding: $uri]", 0, 'debug';

    my $URI = ( $zparse2::MOD_PERL )?$REQ->uri:$ENV{PATH_INFO};
    my $query_string = '';
    $uri=~s/\?(.*)$//;
    $query_string=$1 || '';
    unless( $uri =~ /^\// )
    {
	$uri = $1.'/'.$uri if $URI =~ /^(.*)\/([^\/]*)$/;
    }    
    my $__tmp_root=$root;
    local $root = {};
    $root = zcopyhash $__tmp_root if $do_copy_hash;
    local $currenthash = $root;
    
    my $zmapped_query_string = '&'.zmap( $uri, "$zparse2::DATA_FILES_DIR/$zparse2::SCRIPT_TABLE", 'QUERY_STRING', $query_string );
    $query_string .= '&'.$zmapped_query_string if $zmapped_query_string ne '';
    local $template_name = zmap( $uri, "$zparse2::DATA_FILES_DIR/$zparse2::SCRIPT_TABLE", 'template', $query_string );
    local $script_name = zmap( $uri, "$zparse2::DATA_FILES_DIR/$zparse2::SCRIPT_TABLE", 'script', $query_string );
    
    minizinitparams( $query_string );
    minizinitcookies();

    my $srv = zinclude $script_name, '/', $zparse2::DEFAULT_PERL_MODE if $script_name;
    if( $template_name )
    {
	my $trv = zinclude( $template_name, $zparse2::DOCUMENT_ROOT, $zparse2::DEFAULT_DATA_MODE );
	
        zerror "page not found [$uri]", 254, 'notfound' unless $srv || $trv;
    }
}

$zparse2::JUMPTABLE{webinclude} = \&zwi_webinclude;
sub webinclude { return &{$zparse2::JUMPTABLE{webinclude}}( @_ ); }

$zparse2::unloaddata = 'undef &zwi_webinclude; undef &webinclude;'
	.'undef &zcopyhash; undef &minizinitparam; undef &minizinitcookies;';
