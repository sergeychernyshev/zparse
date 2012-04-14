# show data as xml on demand

my $xml_indent_step=' ';
my $xml_eol="\n";
my $xml_showindex=1;
my $xml_mode=0;
my $xml_contenttype="text/xml";

sub zdumpxml
{
    my ($f, $indent, $arrname ) = @_;
    if( ref $f eq 'HASH' )
    {
		print $xml_eol;
		foreach my $key ( keys %$f )
		{
			if( ref $f->{$key} eq 'ARRAY' )
			{
				zdumpxml( $f->{$key}, $indent, $key );
			}
			else
			{
				print "$indent<$key>";
				zdumpxml( $f->{$key}, $xml_indent_step.$indent, $key ) && print $indent;
				print "</$key>$xml_eol";
			}
		}
		return 1;
    }
    elsif( ref $f eq 'ARRAY' )
    {
		for(my $i=0; $i <= $#$f; ++$i )
		{
			print "$indent<$arrname".($xml_showindex?" index=\"$i\">":'>');
			print $xml_eol if ref $$f[$i] eq 'ARRAY';
			zdumpxml( $$f[$i], $xml_indent_step.$indent, $arrname ) && print $indent;
			print "</$arrname>$xml_eol";
		}
		return 1;	
    }
    else
    {
		print $f;
    }
	return 0;
}

sub xml_zbefore_actual_process
{
	my ( $uri ) = @_;
	
	$xml_indent_step = '   ';
	$xml_eol = "\n";
	$xml_showindex = 1;
	$xml_mode = 0;
	$xml_contenttype = "text/xml";

	my $xmlparams = zmap $uri, "$zparse2::DATA_FILES_DIR/$zparse2::SCRIPT_TABLE",
		'XML', $ENV{QUERY_STRING};
	if( $xmlparams )
	{
		$xml_mode = 1;
		foreach my $p ( split /,/, $xmlparams )
		{
			if( $p eq 'off' )
			{
				$xml_mode=0; last;
			}
			elsif ( $p eq 'noeol' )
			{
				$xml_eol = '';
			}
			elsif ( $p eq 'noindent' )
			{
				$xml_indent_step = '';
			}
			elsif ( $p eq 'noxml' )
			{
				$xml_contenttype = "text/plain";
			}
		}
	}
	return &{$zparse2::JUMPTABLE{zxmlsaved_zbefore_actual_process}}(@_);
}

sub xml_zafter_actual_process
{
	if( $xml_mode )
	{
		untie *STDOUT;
		tie *STDOUT, 'zparse2';
		print "<root>";
		zdumpxml $root, $xml_indent_step;
		print "</root>\n";
		$zparse2::messages = '';
		$zparse2::CONTENT_TYPE = $xml_contenttype;
	}
	return &{$zparse2::JUMPTABLE{zxmlsaved_zafter_actual_process}}(@_);
}

$zparse2::JUMPTABLE{zxmlsaved_zbefore_actual_process} =
	$zparse2::JUMPTABLE{zbefore_actual_process};
$zparse2::JUMPTABLE{zbefore_actual_process} = \&xml_zbefore_actual_process;

$zparse2::JUMPTABLE{zxmlsaved_zafter_actual_process} =
	$zparse2::JUMPTABLE{zafter_actual_process};
$zparse2::JUMPTABLE{zafter_actual_process} = \&xml_zafter_actual_process;

$zparse2::unloaddata = 'undef &zdumpxml; undef &xml_zbefore_actual_process;'
	.'undef &xml_zafter_actual_process;';

