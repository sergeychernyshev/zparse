sub iss_pl
{
        $ENV{PATH_INFO} =~ /^(\/archive\/issue(\d+)\/)/;
        my $archive = "$1";
        my $iss_id = "$2";
        
	my @montha = ('€нвар€','феврал€','марта','апрел€','ма€','июн€',
		'июл€','августа','сент€бр€','окт€бр€','но€бр€','декабр€');

        my @date = localtime(time);
        $zparse2::DAY = $date[3];
        $zparse2::MONTH = $montha[$date[4]];
        $zparse2::YEAR = $date[5]+1900;
        my $query = ($archive)?
                        ("select iss_title, dayofmonth(iss_date) day, "
                        ."month(iss_date) month, year(iss_date) year from issue "
                        ."where iss_id = $iss_id"):
                        ("select iss_title, dayofmonth(iss_date) day, "
                        ."month(iss_date) month, year(iss_date) year, iss_id from issue "
                        ."where iss_date < NOW() and iss_status = 1 "
                        ."order by iss_date desc limit 1");
        $zparse2::ISS_PREFIX = ($archive)?($archive):('/');
        my $result = zexecute( $query )->fetch;
        $zparse2::ISS_TITLE = $result->[0];
        $zparse2::ISS_DAY= $result->[1];
        $zparse2::ISS_MONTH= $montha[$result->[2]-1];
        $zparse2::ISS_YEAR = $result->[3];
        $zparse2::CURRENT_ISS_ID = $result->[4] if (!$archive);

        zerror( "TODAY: $zparse2::DAY $zparse2::MONTH $zparse2::YEAR", 0, 'debug' );
        zerror( "PREFIX: $zparse2::ISS_PREFIX", 0, 'debug' );
        zerror( "DAY: $zparse2::ISS_DAY", 0, 'debug' );
        zerror( "MONTH: $zparse2::ISS_MONTH", 0, 'debug' );
        zerror( "YEAR: $zparse2::ISS_YEAR", 0, 'debug' );
	zerror( "CURRENT_ISS_ID: $zparse2::CURRENT_ISS_ID", 0, 'debug' );

	include "$zparse2::DOCUMENT_ROOT/style/mmenu.pl",'/',$zparse2::DEFAULT_PERL_MODE;
}

sub zlib_zbefore_actual_process
{
    my $rv = &{$zparse2::JUMPTABLE{zlibsaved_zbefore_actual_process}}( @_ );

    if ($zparse2::ZSENDMAILFROM)
    {
	iss_pl();
    }

    return $rv;
};

$zparse2::JUMPTABLE{zlibsaved_zbefore_actual_process} = $zparse2::JUMPTABLE{zbefore_actual_process};
$zparse2::JUMPTABLE{zbefore_actual_process} = \&zlib_zbefore_actual_process;
