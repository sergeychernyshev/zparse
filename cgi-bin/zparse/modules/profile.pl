require "syscall.ph";

$zparse2::prec_timing=1;

sub zprofile_zprofilestart
{
    my ($TIMEVAL_T,$done,$start);
    if( $zparse2::prec_timing )
    {
	$TIMEVAL_T = "LL";
	$start = pack( $TIMEVAL_T, ());
	syscall( &SYS_gettimeofday, $start, 0 ) != -1 or $zparse2::prec_timing=0;
	return $start;
    }
    return time;
}

sub zprofile_zprofileend
{
    my($start) = @_;
    my ($TIMEVAL_T,$done);
    if( $zparse2::prec_timing )
    {
	$TIMEVAL_T = "LL";
	$done = pack( $TIMEVAL_T, ());
	syscall( &SYS_gettimeofday, $done, 0 ) != -1 or $zparse2::prec_timing=0;
	my @start = unpack($TIMEVAL_T, $start);
	my @done = unpack($TIMEVAL_T, $done);
	for( $done[1], $start[1]) { $_ /=1000000 }
	return sprintf "%.4f", ($done[0]+$done[1])-($start[0]+$start[1]);	
    }
    return time - $start;
}

sub zprofilestart { return &{$zparse2::JUMPTABLE{zprofilestart}}( @_ ); }
sub zprofileend { return &{$zparse2::JUMPTABLE{zprofileend}}( @_ ); }

$zparse2::JUMPTABLE{zprofilestart} = \&zprofile_zprofilestart;
$zparse2::JUMPTABLE{zprofileend} = \&zprofile_zprofileend;

$zparse2::unloaddata=
    'undef &zprofilestart; undef &zprofile_zprofilestart;'
    .'undef &zprofileend; undef &zprofile_zprofileend;';
