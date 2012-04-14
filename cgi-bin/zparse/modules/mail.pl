# $Id
# mailer module 

# simple convertor from cp1251 to koi8-r
sub zwin2koi
{
    my $text = shift;
    $text =~ tr {£¤¥¦§¨©ª«¬­®¯³´¶·¸¹º»¼½¾ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿ}
               {¥£¨³©ª´«¬­®¯·¶¦¸¹¤º»¼½¾§áâ÷çäåöúéêëìíîïðòóôõæèãþûýÿùøüàñÁÂ×ÇÄÅÖÚÉÊËÌÍÎÏÐÒÓÔÕÆÈÃÞÛÝßÙØÜÀÑ};
    return $text;
}

# simple convertor from koi8-r to cp1251
sub zkoi2win
{
    my $text = shift;
    $text =~ tr {¥£¨³©ª´«¬­®¯·¶¦¸¹¤º»¼½¾§áâ÷çäåöúéêëìíîïðòóôõæèãþûýÿùøüàñÁÂ×ÇÄÅÖÚÉÊËÌÍÎÏÐÒÓÔÕÆÈÃÞÛÝßÙØÜÀÑ}
               {£¤¥¦§¨©ª«¬­®¯³´¶·¸¹º»¼½¾ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿ};
    return $text;
}

# generic sendmail subroutine
# sendmail $what, $from, $to, $subject
# $data will be processed via zsafeeval
sub zmail_zsendmail
{
    my( $data, $from, $to, $subject ) = @_;
    return unless $data;    
    $data = "Subject: $subject\n$data" if( $subject && !( $data=~/^Subject:/m ) );
    $data = "To: $to\n$data" if( $to && !( $data=~/^To:/m ) );
    $data = "From: $from\n$data" if( $from && !( $data=~/^From:/m ) );
    my $sendmail=$zparse2::SENDMAIL;
    $sendmail.=' -f "'.$from.'"' if ( $from=~/\@/ );

    if( open PIPE, "| $sendmail" ) 
    { 
	print PIPE $data; close PIPE; 
    }
    else { zerror( "cannot open sendmail($sendmail) [$!]", 128, 'warning' ); }
}

# init parameter variables
sub zmail_zbefore_actual_process
{
    if( $zparse2::MOD_PERL )
    {
	$zparse2::SENDMAIL = '/usr/sbin/sendmail -t';
        $zparse2::SENDMAIL = $REQ->dir_config( 'ZSendmail' ) if defined $REQ->dir_config( 'ZSendmail' );
    }
    else
    {
    	$zparse2::SENDMAIL = '/usr/sbin/sendmail -t' unless defined $zparse2::SENDMAIL;
    }
    return &{$zparse2::JUMPTABLE{zmailsaved_zbefore_actual_process}}( @_ );
}

sub zsendmail { return &{$zparse2::JUMPTABLE{zsendmail}}( @_ ); }
$zparse2::JUMPTABLE{zsendmail} = \&zmail_zsendmail;
$zparse2::JUMPTABLE{zmailsaved_zbefore_actual_process} = $zparse2::JUMPTABLE{zbefore_actual_process};
$zparse2::JUMPTABLE{zbefore_actual_process} = \&zmail_zbefore_actual_process;

$zparse2::unloaddata = 	'undef &zmail_zsendmail; undef &zsendmail; undef &zwin2koi; undef &zkoi2win;'
			.' undef &zmail_zbefore_actual_process;';
