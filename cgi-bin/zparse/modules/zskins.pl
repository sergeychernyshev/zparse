sub zskins_zbefore_actual_process
{
    my $URI = $_[0];
    my $rv = &{$zparse2::JUMPTABLE{zskinssaved_zbefore_actual_process}}( @_ );
    
    zconnect;
 
    my $result = (zexecute "select ski_id from site where use_login = ".zquote($zparse2::OWNER))->fetchrow_hashref;

    my $skinname = $result->{ski_id} if defined($result->{ski_id});
    zerror ('No server',0,'noserver') if !defined($skinname);

    zerror ("ZSKINS: template_name: $template_name",0,'debug');

    $template_name =~ s/__skin__/skins\/$skinname/;
    zerror ("ZSKINS: template_name: $template_name",0,'debug');
    return $rv;
}

$zparse2::JUMPTABLE{zskinssaved_zbefore_actual_process} = $zparse2::JUMPTABLE{zbefore_actual_process};
$zparse2::JUMPTABLE{zbefore_actual_process} = \&zskins_zbefore_actual_process;

$zparse2::unloaddata = 
    'undef &zkins_zbefore_actual_process;';
