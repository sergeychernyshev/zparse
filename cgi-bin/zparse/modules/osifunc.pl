use POSIX qw(ceil);
use Time::Local qw (timelocal);

sub killhtml {

	my @text = @_;
	for (my $i=0; $i<= $#text; $i++ ){
		$text[$i] =~ s/&/&amp\;/g;	
		$text[$i] =~ s/</&lt;/g;
		$text[$i] =~ s/>/&gt;/g;
		$text[$i] =~ s/\r?\n/<BR>/g;
		$text[$i] =~ s/^\s+//g;
		$text[$i] =~ s/\s+$//g;
	}
	return wantarray ? @text : $text[0];
}

sub validdate {

# Date format is: day 1..31, month 1..12, year 1..
	my $day = shift;
	my $month = shift;
	my $year = shift;

	my %monthlength = (1,31,2,28,3,31,4,30,5,31,6,30,7,31,8,31,9,30,10,31,11,30,12,31);

	# разбираемся с весокостностью для года начала
	$monthlength{2}=29 if ( !( ($year/4)-ceil($year/4) ) );
	if ($day <= $monthlength{$month}){return 1;}
	else {return 0;}
}

sub urldecode {
    my $todecode = shift;
    return undef unless defined($todecode);
    $todecode =~ tr/+/ /;       # pluses become spaces
    $todecode =~ s/%([0-9a-fA-F]{2})/pack("c",hex($1))/ge;
    return $todecode;
}

sub urlencode {
    my $toencode = shift;
    return undef unless defined($toencode);
    $toencode=~s/([^a-zA-Z0-9_.-])/uc sprintf("%%%02x",ord($1))/eg;
    return $toencode;
}

sub timezdvig{
        use Time::Local qw (timelocal);
        my $day = shift; $day =~ s/^0(\d)$/$1/;
        my $month = shift; $month =~ s/^0(\d)$/$1/;
        my $year = shift; 
        my $time = shift; 
        zerror('INPUTDATE/TIME: '.$day.'-'.$month.'-'.$year.'-'.$time,0,'debug');
        
        my ($hh, $mm, $ss) = split(':',$time);
        $time = timelocal($ss, $mm, $hh, 01, 01, 2000);

        zerror('<b>00:00:00 TIME:</b> '.timelocal(00,00,00,01,01,2000),0,'debug');
        zerror('<b>'.$hh.':'.$mm.':'.$ss.' TIME:</b> '.$time,0,'debug');
        zerror('<b>04:30:00 TIME:</b> '.timelocal(00,30,04,01,01,2000),0,'debug');
        
        my %monthlength = (1,31,2,28,3,31,4,30,5,31,6,30,7,31,8,31,9,30,10,31,11,30,12,31);
        $monthlength{2}=29 if ( !( ($year/4)-ceil($year/4) ) );

        if ( (timelocal(00,00,00,01,01,2000) <= $time) && ($time < timelocal(00,30,04,01,01,2000)) ){
                zerror('I AM IN ZDVIG1',0,'debug');
                $day++;
		zerror('MONTH!!!: '.$month,0,'debug');
		zerror('MONTHLENGTH!!!: '.$monthlength{$month},0,'debug');
                if ($day > $monthlength{$month}){
                        $month++;
			$day = '01';
                        if ($month > 12){
                                $year++; 
                                $month = '01';
                        }
                }
        }
        $month =~ s/^(\d)$/0$1/;
        $day =~ s/^(\d)$/0$1/;  

        zerror('ZDVIG DATE:'.$day.'-'.$month.'-'.$year,0,'debug');
        return ($day, $month, $year);
}

$zparse2::unloaddata = 
    'undef &killlhtml; undef &validdate; undef &urldecode; undef &urlencode; undef &timezdvig';
