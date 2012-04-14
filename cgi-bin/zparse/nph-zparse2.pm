#!/usr/bin/perl
# $Id: nph-zparse2.pm,v 1.1.1.1 2002/01/21 05:25:33 alex Exp $
# uncomment and edit theese if you cannot set environment other way
#  $ENV{ZPARSE_MODULES} = '';
#  $ENV{ZPARSE_MODULES_PATH} = '';

$ENV{CHARSET}="windows-1251";
 	
$ENV{ZPARSE_MODULES} = 'zeperl.pl;services.pl;compat.pl;db.pl;zmeta.pl;debug.pl;colordebug.pl;zguard.pl;osifunc.pl;webinclude.pl;mail.pl;xmldump.pl;zguardauto.pl' if (!defined($ENV{ZPARSE_MODULES}));
$ENV{ZPARSE_MODULES_PATH} = '/home/fat.program.ru/www/cgi-bin/zparse/modules/' if (!defined($ENV{ZPARSE_MODULES_PATH}));

package zparse2;
require POSIX;
use strict;
use vars qw( $REQ $root $currenthash $template_name $script_name );
use locale;
my $messages;

# Zparse2 API functions
# definitions

sub zsafeeval;
sub zloadfile;
sub zmap;
sub zerror;
sub zexit;
sub zsendheader;
sub include;
sub zinclude;
sub zoutdebug;
sub zoutheaders;
sub zprocessdata;
sub zbefore_actual_process;
sub zactual_process;
sub zafter_actual_process;
sub zchildinit;
sub zchildexit;
sub zloadmodule;

#TODO:
# all work with $root -> root.pl

# Zparse2 core functions
sub zprocessrequest
{
	# TODO: maybe remove $zparse2::JUMPTABLESNAPSHOT, use local $zparse2::JUMPTABLE
	my $URI;
	my $some_modules_loaded=0;
	$zparse2::CURRENT_DIR =~ s/\/[^\/]+$/\//;
	$zparse2::messages='';
	$zparse2::error_script='';
	$zparse2::RETURNCODE = 200;
	$root = {};
	$currenthash = $root;
	$zparse2::currentprefix = "/";
	untie *STDOUT;
	tie *STDOUT, 'zparse2';

	$zparse2::CONTENT_TYPE = 'text/html';
	$zparse2::MAX_CACHE_SIZE = 0; # 0 - unlimited
	$zparse2::MAX_MAP_ITERATIONS = 10;
	$zparse2::DOCUMENT_ROOT = $ENV{DOCUMENT_ROOT};
	$zparse2::ZLOCALE = 'ru_RU.cp1251';
	$zparse2::MODULES = '';
	$zparse2::DEFAULT_DATA_MODE = 1;
	$zparse2::DEFAULT_PERL_MODE = 0;
	$zparse2::SCRIPT_TABLE='script_table';
	%zparse2::ERROR_REDIRECT = ('error','','usererror','','notfound','');
	if( $zparse2::MOD_PERL ) 
	{ 
		$zparse2::ZERRORONINCLUDE = 'off';
		$zparse2::ZPARSEPARAMS = 'on';
		$zparse2::DEBUG=255; 
		$zparse2::LOGLEVEL=254;
		$zparse2::MAX_FILE_LENGTH = 500000;
		$zparse2::DEBUG = $REQ->dir_config( 'ZDebug' ) if defined $REQ->dir_config( 'ZDebug' );
		$zparse2::LOGLEVEL = $REQ->dir_config( 'ZLogLevel' ) if defined $REQ->dir_config( 'ZLogLevel' );
		$zparse2::MAX_FILE_LENGTH = $REQ->dir_config( 'ZMaxFileLength' ) if defined $REQ->dir_config( 'ZMaxFileLength' );
		$zparse2::MAX_MAP_ITERATIONS = $REQ->dir_config( 'ZMaxMapIterations' ) if defined $REQ->dir_config( 'ZMaxMapIterations' );
		$zparse2::DEFAULT_DATA_MODE = $REQ->dir_config( 'ZDefaultDataMode' ) if defined $REQ->dir_config( 'ZDefaultDataMode' );
		$zparse2::DOCUMENT_ROOT = $REQ->dir_config( 'ZDocumentRoot' ) if defined $REQ->dir_config( 'ZDocumentRoot' );
		$zparse2::DATA_FILES_DIR = $zparse2::DOCUMENT_ROOT.'/datafiles';
		$zparse2::DATA_FILES_DIR = $REQ->dir_config( 'ZDataFilesDir' ) if defined $REQ->dir_config( 'ZDataFilesDir' );
		$zparse2::ZLOCALE = $REQ->dir_config( 'ZLocale' ) if defined $REQ->dir_config( 'ZLocale' );
		$zparse2::MODULES_PATH = $ENV{ZPARSE_MODULES_PATH}; 
		$zparse2::MODULES_PATH = $REQ->dir_config( 'ZModulesPath' ) if defined $REQ->dir_config( 'ZModulesPath' );		 
		$zparse2::MODULES = $REQ->dir_config( 'ZModules' ) if defined $REQ->dir_config( 'ZModules' );
		$zparse2::ZERRORONINCLUDE = $REQ->dir_config( 'ZErrorOnInclude' ) if defined $REQ->dir_config( 'ZErrorOnInclude' );
		$zparse2::ZPARSEPARAMS = $REQ->dir_config( 'ZparseParams' ) if defined $REQ->dir_config( 'ZparseParams' );
		$zparse2::SCRIPT_TABLE = $REQ->dir_config( 'ZScriptTable' ) if defined $REQ->dir_config( 'ZScriptTable' );
		$zparse2::MAX_CACHE_SIZE = $REQ->dir_config( 'ZMaxCacheSize' ) if defined $REQ->dir_config( 'ZMaxCacheSize' );
		my $tmp = $REQ->dir_config( 'ZErrorRedirect' ) if defined $REQ->dir_config( 'ZErrorRedirect' );
		%zparse2::ERROR_REDIRECT = ( %zparse2::ERROR_REDIRECT, split( /,/, $tmp ) );
		$zparse2::ZERRORONINCLUDE = ( lc($zparse2::ZERRORONINCLUDE) eq 'off')?0:1;
		$zparse2::ZPARSEPARAMS = ( lc($zparse2::ZPARSEPARAMS) eq 'off')?0:1;
		$URI = $REQ->uri;
	}
	else
	{
		$zparse2::ZERRORONINCLUDE = '0';
		$zparse2::ZPARSEPARAMS = '1';
		$zparse2::DATA_FILES_DIR = $zparse2::DOCUMENT_ROOT.'/datafiles'; 
		my $zparamspath = $ENV{SCRIPT_FILENAME};
		$zparamspath =~ s/\/[^\/]+$/\//;
		zinclude "$zparamspath/zparseparams.pl", "/", 0;
		$URI = $ENV{PATH_INFO};
	}
	if( $zparse2::ZPARSEPARAMS )
	{
		my $zparams_name = zmap( $ENV{HTTP_HOST}, "$zparse2::DATA_FILES_DIR/$zparse2::SCRIPT_TABLE", 'params', $ENV{QUERY_STRING} );
		zinclude $zparams_name, '/', 0 if $zparams_name;
	}	
	POSIX::setlocale( &POSIX::LC_ALL, $zparse2::ZLOCALE );
	if( $zparse2::MODULES )
	{
		foreach my $module ( split /;/, $zparse2::MODULES )
		{
			next unless $module;
			zloadmodule $module;			
		}
		$some_modules_loaded = 1 if $zparse2::MOD_PERL;
	}
	zbefore_actual_process $URI;
	zactual_process $URI;
	
OUT_HEADERS:
	# TODO:  protect from loops if error occured later
	zafter_actual_process $URI;
	$zparse2::scripts_output = <STDOUT>;
	untie *STDOUT;
	
	zoutheaders;
	# TODO: define sub zprint = $REQ->print for mod_perl, = print for CGI
	# TODO: more general processing of error codes.
	if( $zparse2::MOD_PERL )
	{
		if( ($REQ->method ne "HEAD" )
			&& ($zparse2::RETURNCODE != 301)
			&& ($zparse2::RETURNCODE != 302)
			)
		{
			$REQ->print( $zparse2::scripts_output );
			zoutdebug;
		}
	}
	else
	{
		if( ($ENV{REQUEST_METHOD} ne "HEAD" )
			&& ($zparse2::RETURNCODE != 301)
			&& ($zparse2::RETURNCODE != 302)
			)
		{
			print( $zparse2::scripts_output );
			zoutdebug;
		}
	}
	
	%zparse2::JUMPTABLE = %zparse2::JUMPTABLE_SNAPSHOT if $zparse2::MOD_PERL;
	if( $some_modules_loaded )
	{
		# TODO: new functions: zunloadmodule and zunloadallmodules ( maybe in modules.pl )
		foreach my $module ( %zparse2::UNLOAD_DATA )
		{
			zerror "handler: [$module][$zparse2::GLOBAL_ERROR]", 254, 'error' unless zsafeeval $zparse2::UNLOAD_DATA{$module};
			delete $zparse2::LOADED_MODULES{$module}
		}		
	}	
}

sub handler
{
	$REQ = shift;	
	Apache->request($REQ);
	$zparse2::CURRENT_DIR = $REQ->filename;
	$zparse2::MOD_PERL = 1;

	zprocessrequest;	
	
	return 200; # $zparse2::RETURNCODE;
}

sub transform
{
	my $REQ = shift;
	
	$zparse2::DEBUG=256; 
	$zparse2::LOGLEVEL=256;
	$zparse2::MAX_FILE_LENGTH = 500000;	
	$zparse2::MAX_MAP_ITERATIONS = 10;
	%zparse2::ERROR_REDIRECT = ();
	$zparse2::DOCUMENT_ROOT = $ENV{DOCUMENT_ROOT};
	$zparse2::DOCUMENT_ROOT = $REQ->dir_config( 'ZDocumentRoot' ) if defined $REQ->dir_config( 'ZDocumentRoot' );
	$zparse2::DATA_FILES_DIR = $zparse2::DOCUMENT_ROOT.'/datafiles'; 
	$zparse2::DATA_FILES_DIR = $REQ->dir_config( 'ZDataFilesDir' ) if defined $REQ->dir_config( 'ZDataFilesDir' );
	$zparse2::SCRIPT_TABLE = 'script_table';
	
	my $script_table = zmap $REQ->header_in('Host'), "$zparse2::DATA_FILES_DIR/$zparse2::SCRIPT_TABLE", 'transf', $REQ->args;
	$script_table = "$zparse2::DATA_FILES_DIR/$zparse2::SCRIPT_TABLE" unless $script_table;
	my $filename = zmap $REQ->uri, $script_table, 'iurifile', $REQ->args;
	unless( $filename )
	{
		my $filename = zmap $REQ->uri, $script_table, 'urifile', $REQ->args;
		if( $filename )
		{
			$REQ->log_error( "zparse2: mapping ".$REQ->uri."->$filename" );
			$REQ->filename( $filename );
			return 0;
		}
	}
OUT_HEADERS:
	return -1;
}

sub cgi_handler
{
	$zparse2::CURRENT_DIR = $ENV{'PATH_TRANSLATED'};
	$zparse2::MOD_PERL = 0;

	zprocessrequest;
}

sub childinit
{
	zchildinit;
}

sub childexit
{
	zchildexit;
}

sub TIEHANDLE
{
	my $buffer="";
	bless \$buffer;
}

sub PRINT
{
	my $buffer = shift;
	for( @_ )
	{
		$$buffer.=$_;
	}
}

sub READLINE
{
	my $buffer = shift;
	return $$buffer;
}

# Zparse2 API functions

# implementations
sub zcore_zsafeeval
{
	my $data = shift;
	undef $zparse2::GLOBAL_ERROR;
	local $SIG{__WARN__} = sub{ $zparse2::GLOBAL_ERROR = $_[0]; };
	my $rv = defined( eval "$data;" );
	$zparse2::error_script = $data if $zparse2::GLOBAL_ERROR;
	return 0 if $zparse2::GLOBAL_ERROR;
	$zparse2::GLOBAL_ERROR = "$@" unless $rv;
	$zparse2::error_script = $data if $zparse2::GLOBAL_ERROR;
	return 0 if $zparse2::GLOBAL_ERROR;
	return 1;
}

sub zcore_zloadfile
{
	my( $filename, $mode ) = @_;
	$filename=~s/\/+/\//g;
	$mode = 0 unless defined( $mode );
	zerror "zloadfile: $filename, $mode", 0, 'debug';
	my $timestamp = (stat($filename))[9];
	if( $zparse2::file_timestamp{$filename} != $timestamp )
	{
		zerror "zloadfile: invalidate cached data", 0, 'debug';
		delete $zparse2::file_cache{$filename};
		delete $zparse2::file_cache2{$filename};
		delete $zparse2::file_cache_access{$filename};
		delete $zparse2::file_cache_size{$filename};
		delete $zparse2::file_cache2_size{$filename};
	}
	my $data;
	if( defined( $zparse2::file_cache2{$filename} ) )
	{
		zerror "zloadfile: use supercached data", 0, 'debug';
		$data = $zparse2::file_cache2{$filename};
		$zparse2::file_cache_access{$filename} = time;
	}
	elsif( defined( $zparse2::file_cache{$filename} ) )
	{
		zerror "zloadfile: use cached data", 0, 'debug';
		$data = $zparse2::file_cache{$filename};
		if( $mode )
		{
			zerror "zloadfile: processing data.", 0, 'debug';
			$data = zprocessdata( $data, $mode );			
		}
		$zparse2::file_cache2{$filename} = $data;
		$zparse2::file_cache_access{$filename} = time;
	}
	else
	{
		zerror "zloadfile: load data from file", 0, 'debug';
		if( open( FILE, $filename ) )
		{
			if( !defined( read( FILE, $data, $zparse2::MAX_FILE_LENGTH ) ) ) 
			{
				zerror "zloadfile: [$!]:$filename", 126, 'warning';
				return undef;
			}
			close( FILE );
		}
		else
		{
			zerror "zloadfile: [$!]:$filename", 126, 'warning';
			return undef;
		}
		my $datalength = length $data;
		my $cache_please = 1;
		if( $zparse2::MAX_CACHE_SIZE )
		{
			while(  $zparse2::file_cache_total_size+$datalength > $zparse2::MAX_CACHE_SIZE )
			{
				my $mintime = time;
				my $found_filename = '';
				foreach my $filename_incache ( keys %zparse2::file_cache )
				{
					if( $zparse2::file_cache_access{$filename_incache} < $mintime )
					{
						$mintime = $zparse2::file_cache_access{$filename};
						$found_filename = $filename_incache;
					}
				}
				if( $found_filename )
				{
					zerror "zloadfile: delete cached data for file '$found_filename'", 0, 'debug';
					$zparse2::file_cache_total_size -= $zparse2::file_cache_size{$found_filename} + $zparse2::file_cache2_size{$found_filename};
					delete $zparse2::file_cache{$found_filename};
					delete $zparse2::file_cache2{$found_filename};
					delete $zparse2::file_cache_access{$found_filename};
					delete $zparse2::file_cache_size{$found_filename};
					delete $zparse2::file_cache2_size{$found_filename};
				}
				else
				{
					zerror "zloadfile: cannot cache. file too big", 0, 'debug';
					$cache_please = 0
				}
			}
		}
		if( $cache_please )
		{
			$zparse2::file_cache{$filename} = $data;
			$zparse2::file_cache_total_size += ( $zparse2::file_cache_size{$filename} = $datalength);
			$zparse2::file_cache_access{$filename} = time;
		}
		if( $mode )
		{
			zerror "zloadfile: processing data.", 0, 'debug';
			$data = zprocessdata( $data, $mode );
		}
		if( $cache_please )
		{
			$zparse2::file_cache2{$filename} = $data;
			$zparse2::file_cache_total_size += ( $zparse2::file_cache2_size{$filename} = length $data );
			$zparse2::file_timestamp{$filename} = $timestamp;
		}
	}
	return $data;
}

sub zcore_zmap
{
	my( $srcfile, $tablefile, $maptype, $querystring ) = @_;
	
	$srcfile=~s/\/+/\//g;
	$tablefile=~s/\/+/\//g;

	zerror "zmap: $srcfile, $tablefile, $maptype, $querystring", 0, 'debug';
	my $cacheind = "$srcfile\:\:$maptype\:\:$querystring";
	# dirty hack to speed up zmap a little
	my $timestamp = (stat($tablefile))[9];
	if( $timestamp )
	{
		if( $zparse2::file_timestamp{$tablefile} != $timestamp )
		{
			my $order = 0;
			my $table = zloadfile $tablefile;
			zerror 'zmap: processing loaded file', 0, 'debug';
			undef $zparse2::map_cache{$tablefile};
			undef $zparse2::map_cache2{$tablefile};
			foreach my $line ( split /\n/, $table )
			{
				next if /\#/;
				if( $line =~ /^\s*(\S+)\s*(\S+)\s*(\S+)(\s*(\S+))*\s*$/ )
				{
					my $queryre = defined($5)?$5:'.*';
					$zparse2::map_cache{$tablefile}->{$1}->{$order++} = [$2, $3, $queryre ];
				}
			}
		}
	}
	else { zerror "zmap: '$tablefile' not exists. using as script-build table name", 126, 'warning'; }
	if( defined( $zparse2::map_cache2{$tablefile}->{$cacheind} ) )
	{
		zerror 'zmap: supercached data $dstfile='.$zparse2::map_cache2{$tablefile}->{$cacheind}, 0, 'debug';
		return $zparse2::map_cache2{$tablefile}->{$cacheind};
	}
	my $dstfile = $srcfile;
	my $matched = 0;
	foreach my $order ( sort {$a<=>$b} keys %{$zparse2::map_cache{$tablefile}->{$maptype}} )
	{
		my $line = $zparse2::map_cache{$tablefile}->{$maptype}->{$order};
		my $queryre = $line->[2];
		if( $querystring =~ /$queryre/ )
		{
			my $olddstfile = $dstfile;
			my $rv = 0;
			my $i = $zparse2::MAX_MAP_ITERATIONS;
			while( defined( eval '$rv=($dstfile=~s#'.$line->[0].'#'.$line->[1].'#);' )&&$rv&&$i )
			{
				zerror "zmap: current \$dstfile=$dstfile", 0, 'debug';
				$matched=1;
				last if $olddstfile eq $dstfile;
				$olddstfile = $dstfile;
				$i--;
			}
			zerror 'zmap: max iterations count reached. probably error in script_table', 254, 'error' unless $i;
			last if $matched;
		}
	}
	$dstfile = '' unless $matched;
	$zparse2::map_cache2{$tablefile}->{$cacheind} = $dstfile;
	zerror "zmap: \$matched=$matched, \$dstfile=$dstfile", 0, 'debug';
	return $dstfile;
}

sub zcore_zerror
{	
	my( $errtext, $level, $flag ) = @_;
	$level = 255 unless defined( $level );
	$flag = 'warning' unless defined( $flag );
	$zparse2::messages.="$flag\: $errtext<BR>\n" if $level>=$zparse2::DEBUG;
	print STDERR "zparse2: $flag\: $errtext, REDIRECT:".$zparse2::ERROR_REDIRECT{$flag}."\n" if $level>=$zparse2::LOGLEVEL;
	if( defined( $zparse2::ERROR_REDIRECT{$flag} ) && !$zparse2::PROCESS_ERROR )
	{
		untie *STDOUT;
		tie *STDOUT, 'zparse2';
		$zparse2::lasterrtext = $errtext;
		$zparse2::lastflag = $flag;
		$zparse2::PROCESS_ERROR = 1;
		unless( zinclude $zparse2::ERROR_REDIRECT{$flag} )
		{
			print "<html><head><title>zparse2 error</title>"
				 ."</head><body>There is error. Report is mailed to webmaster. Please be back later.</body></html>";
		}
		$zparse2::PROCESS_ERROR = 0;
	goto OUT_HEADERS;
	}
}

sub zcore_zexit
{
	my $retcode = shift;
	zerror 'zexit: exiting... '.$retcode, 0, 'debug';
	$zparse2::RETURNCODE = $retcode if defined( $retcode );
	goto OUT_HEADERS;
}

sub zcore_zsendheader_modperl
{
	$REQ->send_cgi_header( shift );
}

sub zcore_zsendheader_cgi
{
	push @zparse2::HEADERS, shift;
}

sub zcore_include
{
	my( $filenames, $rootdir, $mode, $nozmap, $docurrentdirchange ) = @_;
	$rootdir = $zparse2::DOCUMENT_ROOT unless defined $rootdir;
	$mode = $zparse2::DEFAULT_DATA_MODE unless defined $mode;
	$nozmap = 1 unless defined $nozmap;
	$docurrentdirchange = 1 unless defined $docurrentdirchange;
	my $rv = 1;

	foreach my $filename ( split /;/, $filenames )
	{
		next if !$filename;
		if( $filename =~ /^\// ) { $filename = "$rootdir/$filename"; }
		else { $filename = "$zparse2::CURRENT_DIR/$filename"; }		
#		unless( $nozmap )
#		{
#			my $zmapfilename=$filename;
#			$zmapfilename=~s/^$rootdir//;
#			my $escript_name = zmap $zmapfilename, "$zparse2::DATA_FILES_DIR/$zparse2::SCRIPT_TABLE", 'escript';
#			zinclude $escript_name, '/', $zparse2::DEFAULT_PERL_MODE if $escript_name;
#		}		
		my $data = zloadfile( "$filename", $mode );
		unless( defined $data )
		{
			zerror "include: error loading file: $filename", 254, 'error' if $zparse2::ZERRORONINCLUDE;
			$rv = 0;
		}
		my $TMP_CURRENT_DIR = $zparse2::CURRENT_DIR;
		if ($docurrentdirchange)
		{
			$zparse2::CURRENT_DIR = $filename;
			$zparse2::CURRENT_DIR =~ s/\/[^\/]+$/\//;
		}

		if( $data )
		{
			#zerror "processed data: $data", 0, 'debug';
			zerror "include: $zparse2::GLOBAL_ERROR", 254, 'error' unless zsafeeval $data;
		}
		if ($docurrentdirchange)
		{
			$zparse2::CURRENT_DIR = $TMP_CURRENT_DIR;
		}
	}
	return $rv;
}

sub zcore_zoutdebug
{
	if( $zparse2::error_script )
	{
		$zparse2::error_script =~ s/</&lt;/g;
		$zparse2::error_script =~ s/>/&gt;/g;
		$zparse2::error_script =~ s/\n/<br><br>/g;
	}
	if( $zparse2::MOD_PERL )
	{
		$REQ->print( "<br><br><a name=\"debug\"></a>"
			."<table border=1 cellpadding=5 cellspacing=0 bgcolor=\"white\">"
			."<tr><td>mod_perl-mode</td></tr>"
			."<tr><td><font color=\"black\">$zparse2::messages</td></tr>"
			."</table>\n" )
			if $zparse2::messages;
		$REQ->print( "<br><br><a name=\"script\"></a>"
			."<table border=1 cellpadding=5 cellspacing=0 bgcolor=\"white\">"
			."<tr><td>script with error</td></tr>"
			."<tr><td><font color=\"black\">$zparse2::error_script</td></tr>"
			."</table>\n" )
			if $zparse2::error_script;
	}
	else
	{
		print( "<br><br><a name=\"debug\"></a>"
			."<table border=1 cellpadding=5 cellspacing=0 bgcolor=\"white\">"
			."<tr><td>cgi-mode</td></tr>"
			."<tr><td><font color=\"black\">$zparse2::messages</td></tr>"
			."</table>\n" )
			if $zparse2::messages;
		print( "<br><br><a name=\"script\"></a>"
			."<table border=1 cellpadding=5 cellspacing=0 bgcolor=\"white\">"
			."<tr><td>script with error</td></tr>"
			."<tr><td><font color=\"black\">$zparse2::error_script</td></tr>"
			."</table>\n" )
			if $zparse2::error_script;
	}
}

sub zcore_zoutheaders
{
	if( $zparse2::MOD_PERL )
	{
		$REQ->status( $zparse2::RETURNCODE );
		$REQ->content_type( $zparse2::CONTENT_TYPE );
		$REQ->send_http_header;
	}
	else
	{
		my $loc = POSIX::setlocale( &POSIX::LC_TIME, "C" );
		print $ENV{SERVER_PROTOCOL}.' '.$zparse2::RETURNCODE."\n";	
		print 'Date: '.POSIX::strftime( "%a, %d %b %Y %H:%M:%S GMT", gmtime )."\n";
		print 'Server: '.$ENV{SERVER_SOFTWARE}."\n";
		foreach my $hdr ( @zparse2::HEADERS )
		{
			print $hdr."\n";
		}
		print 'Content-type: '.$zparse2::CONTENT_TYPE;
		print '; charset='.$ENV{CHARSET} if (defined($ENV{CHARSET}) && ($ENV{CHARSET} ne ''));
		print "\n";
		print 'Expires: Thu, 01 January 1970 00:00:01 GMT'."\n";
		print 'Last-Modified: '.POSIX::strftime( "%a, %d %b %Y %H:%M:%S GMT", gmtime )."\n\n";	
		POSIX::setlocale( &POSIX::LC_TIME, $loc );
	}
}

sub zcore_zprocessdata
{
	my( $data, $mode ) = @_;
	if( $mode==1 )
	{
		$data =~ s/\"/\\\"/mg; $data =~ s/\$/\\\$/mg;
		$data = "print \"$data\"";
	}
	return $data;
}

sub zcore_zempty
{
	return 1;
}

sub zcore_zbefore_actual_process
{	
	my $URI = shift;
	my $mapped_QUERY_STRING = zmap( $URI, "$zparse2::DATA_FILES_DIR/$zparse2::SCRIPT_TABLE", 'QUERY_STRING', $ENV{QUERY_STRING} );

	$ENV{QUERY_STRING} .= '&'.$mapped_QUERY_STRING if $mapped_QUERY_STRING ne '';
	$template_name = zmap( $URI, "$zparse2::DATA_FILES_DIR/$zparse2::SCRIPT_TABLE", 'template', $ENV{QUERY_STRING} );
	$script_name = zmap( $URI, "$zparse2::DATA_FILES_DIR/$zparse2::SCRIPT_TABLE", 'script', $ENV{QUERY_STRING} );
}

sub zcore_zactual_process
{
	my $URI = shift;
	my $srv = zinclude $script_name, '/', $zparse2::DEFAULT_PERL_MODE if $script_name;
	if( $template_name )
	{
		my $trv = zinclude( $template_name, $zparse2::DOCUMENT_ROOT, $zparse2::DEFAULT_DATA_MODE );
		zerror "page not found [$URI]", 254, 'notfound' unless $srv || $trv;
	}
}

sub zcore_zloadmodule
{
	my $module = shift;	
	my $data;
	unless( $zparse2::LOADED_MODULES{$module} )
	{
		zerror "zloadmodule: loading module [$module]", 0, 'debug';
		undef $zparse2::unloaddata;

		my @modulespaths = split /:/, $zparse2::MODULES_PATH;
		foreach my $key ( @modulespaths )
		{
			last if defined( $data = zloadfile( "$key/$module" ) );
		}
		 
		zerror "zloadmodule: error loading module [$module]", 254, 'error' unless defined $data ;

		zerror "zloadmodule: error loading module [$module][$zparse2::GLOBAL_ERROR]", 254, 'error' unless zsafeeval $data;
		$zparse2::LOADED_MODULES{$module} = 1;
		$zparse2::UNLOAD_DATA{$module} = $zparse2::unloaddata;
	}
}

# jumptable
sub zsafeeval { return &{$zparse2::JUMPTABLE{zsafeeval}}( @_ ); }
sub zloadfile { return &{$zparse2::JUMPTABLE{zloadfile}}( @_ ); }
sub zmap { return &{$zparse2::JUMPTABLE{zmap}}( @_ ); }
sub zerror { return &{$zparse2::JUMPTABLE{zerror}}( @_ ); }
sub zexit { return &{$zparse2::JUMPTABLE{zexit}}( @_ ); }
sub zsendheader { return &{$zparse2::JUMPTABLE{zsendheader}}( @_ ); }
sub include { return &{$zparse2::JUMPTABLE{include}}( @_ ); }
sub zinclude { return &{$zparse2::JUMPTABLE{zinclude}}( @_ ); }
sub zoutdebug { return &{$zparse2::JUMPTABLE{zoutdebug}}( @_ ); }
sub zoutheaders { return &{$zparse2::JUMPTABLE{zoutheaders}}( @_ ); }
sub zprocessdata { return &{$zparse2::JUMPTABLE{zprocessdata}}( @_ ); }
sub zbefore_actual_process { return &{$zparse2::JUMPTABLE{zbefore_actual_process}}( @_ ); }
sub zactual_process { return &{$zparse2::JUMPTABLE{zactual_process}}( @_ ); }
sub zafter_actual_process { return &{$zparse2::JUMPTABLE{zafter_actual_process}}( @_ ); }
sub zchildinit { return &{$zparse2::JUMPTABLE{zchildinit}}( @_ ); }
sub zchildexit { return &{$zparse2::JUMPTABLE{zchildexit}}( @_ ); }
sub zloadmodule { return &{$zparse2::JUMPTABLE{zloadmodule}}( @_ ); }

$zparse2::JUMPTABLE{zsafeeval} = \&zcore_zsafeeval;
$zparse2::JUMPTABLE{zloadfile} = \&zcore_zloadfile;
$zparse2::JUMPTABLE{zmap} = \&zcore_zmap;
$zparse2::JUMPTABLE{zerror} = \&zcore_zerror;
$zparse2::JUMPTABLE{zexit} = \&zcore_zexit;
$zparse2::JUMPTABLE{zdumpvar} = \&zcore_zdumpvar;
$zparse2::JUMPTABLE{include} = \&zcore_include;
$zparse2::JUMPTABLE{zinclude} = \&zcore_include;
$zparse2::JUMPTABLE{zprocessdata} = \&zcore_zprocessdata;
$zparse2::JUMPTABLE{zbefore_actual_process} = \&zcore_zbefore_actual_process;
$zparse2::JUMPTABLE{zactual_process} = \&zcore_zactual_process;
$zparse2::JUMPTABLE{zafter_actual_process} = \&zcore_zempty;
$zparse2::JUMPTABLE{zchildinit} = \&zcore_zempty;
$zparse2::JUMPTABLE{zchildexit} = \&zcore_zempty;
$zparse2::JUMPTABLE{zloadmodule} = \&zcore_zloadmodule;
$zparse2::JUMPTABLE{zoutdebug} = \&zcore_zoutdebug;
$zparse2::JUMPTABLE{zoutheaders} = \&zcore_zoutheaders;

$zparse2::MOD_PERL = defined $ENV{MOD_PERL};
if( $zparse2::MOD_PERL )
{
	$zparse2::JUMPTABLE{zconfigvar} = \&zcore_zconfigvar_modperl;
	$zparse2::JUMPTABLE{zconfigvarbool} = \&zcore_zconfigvarbool_modperl;
	$zparse2::JUMPTABLE{zconfigvarhash} = \&zcore_zconfigvarhash_modperl;
	$zparse2::JUMPTABLE{zsendheader} = \&zcore_zsendheader_modperl;
}
else
{
	$zparse2::JUMPTABLE{zconfigvar} = \&zcore_zconfigvar_cgi;
	$zparse2::JUMPTABLE{zconfigvarbool} = \&zcore_zconfigvarbool_cgi;
	$zparse2::JUMPTABLE{zconfigvarhash} = \&zcore_zconfigvarhash_cgi;
	$zparse2::JUMPTABLE{zsendheader} = \&zcore_zsendheader_cgi;
}
$zparse2::DEBUG=255;
$zparse2::LOGLEVEL=254; 
$zparse2::MAX_FILE_LENGTH = 500000;
$zparse2::MODULES = $ENV{ZPARSE_MODULES};
$zparse2::MODULES_PATH = $ENV{ZPARSE_MODULES_PATH};

my @modulespaths = split /:/, $zparse2::MODULES_PATH;

foreach my $module ( split /;/, $zparse2::MODULES )
{
	my $data;
	next unless $module;

	foreach my $key ( @modulespaths ) 
	{
	last if defined( $data = zloadfile( "$key/$module" ) );
	}
	die "error loading module [$module]" unless defined $data;
	die "error loading module [$module][$zparse2::GLOBAL_ERROR]" unless zsafeeval $data;
	$zparse2::LOADED_MODULES{$module} = 1;
}
%zparse2::JUMPTABLE_SNAPSHOT = %zparse2::JUMPTABLE if $zparse2::MOD_PERL;
unless( $zparse2::MOD_PERL )
{
	childinit();
	cgi_handler();
	childexit();
}

1;
