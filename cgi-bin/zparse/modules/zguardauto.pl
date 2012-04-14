zloadmodule 'zguard.pl';

sub zgauto_zbefore_actual_process
{
	my $rv = &{$zparse2::JUMPTABLE{zgautosaved_zbefore_actual_process}}( @_ );
	my $URI = shift;
	my $right = zmap $URI, "$zparse2::DATA_FILES_DIR/$zparse2::SCRIPT_TABLE",
		'guard', $ENV{QUERY_STRING};

	if( $right && !zhasaccess( $right ) )
	{
		zerror "access denied for uri \"$URI\"", 0, 'accessdenied';
	}
	return $rv;
}

$zparse2::JUMPTABLE{zgautosaved_zbefore_actual_process} = $zparse2::JUMPTABLE{zbefore_actual_process};
$zparse2::JUMPTABLE{zbefore_actual_process} = \&zgauto_zbefore_actual_process;

$zparse2::unloaddata = 'undef &zgauto_zbefore_actual_process;';

