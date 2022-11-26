#!/usr/bin/perl -w

###########################################################################
## Program: aix_snaescon.pl                                               #
## Version: 3.6                                                           #
## Author : Near Him Lim                                                  #
## Company: Royal Bank of Canada                                          #
## Dept   : CN&S                                                          #
## Date   : 98 03 30                                                      #
## Purpose: Check for escon link down                                     #
## Env    : Perl 5.004                                                    #
## Usage  : aix_snaescon.pl <device>                                      #
## Return : None                                                          #
###########################################################################

require dmenv;
require dmlib;

my $numbarg = @ARGV;
($numbarg != 1) && die("Usage: $0 <escon_config_name>\n");

my ($path, $path_src, $eventlog, $tecserver, $armvalue, $methodi, $maint);
my (%sevtec, $host, $msgarm, $msgrearm, $class, $source, $action_id, $lockfile);

my ($cron, $rcflag, $line, $sev, $armlog, $testfail);

# Create object class to allow access to Tivoli environ variables
# Note: tecserver, class, source and , method are default values, they are
#       overwrited in fsp.txt configuration file
#
my $dm_env = getlocal_dm_env dmenv();
my $tec_env = getlocal_tec_env dmenv();
my $res_env = getlocal_res_env dmenv('class'    => 'Pstmsg_procstat',
                                     'source'   => 'VVPOST',
                                     'method'   => 'postemsg',
                                     'evtlockfile' => 'evtlock');

&getlocalenv;
&getresenv;
&gettecenv;

#
# Create an object class $sub to allow access to Tivoli library
#
my $sub = new dmlib;

$host=dmlib::gethost($sub);

my $escon_config = shift(@ARGV);
open(CONFIG, "$escon_config") || die("Cannot read the escon configname $escon_config\n");
my @escon_list = <CONFIG>;
close (CONFIG);

#
# Parse the configuration file and process it
#
$line = 0;
while ( $line <= $#escon_list ) {

      if ( $escon_list[$line] !~ /#/ ) {
         if ( $escon_list[$line] !~ /!/ ) {

            (-e $maint) && last;

            $testfail = 0;
            ($device, $sev, $armlog,$action_id) = split(/:/, $escon_list[$line]);
            $testfail = &chk_escon($device);

            $severity = $sevtec{$sev}; 
            $armfile = $path.$armlog.$severity.".t";

            if ($testfail) {

               $sendarm = dmlib::chk_armstatus($sub, $armfile, $armvalue);
               $message = dmlib::parse_gen_msg($sub, $msgarm, $armlog, $device); 
       
            }
            else {
                   $sendarm = dmlib::chk_rearmstatus($sub, $armfile);
                   $message = dmlib::parse_gen_msg($sub, $msgrearm, $armlog); 
                   $severity = $sevtec{'h'};

            }

            ($sendarm) && dmlib::send_alert($sub, $message, $device, $method, $severity, $class,
                                    $source, $host, $path_src, $eventlog, $evtlockfile, $tecserver); 

            # Execute the action via Sentry or directly
            if ($cron) {
                 ($testfail) && ($sendarm) && ($action_id) && dmlib::exec_unix_command($sub, $eventlog, $evtlockfile, $action_id);
            } else {
                    ($testfail) && ($sendarm) && ($action_id) && ($rcflag = 1);
                    ($testfail) && ($sendarm) && ($action_id) && print("#$action_id ~\n");
            }

         }
         else {

               (undef, $msgarm, $msgrearm, $cron, $maint, $methods) = split(/[\t\n\%]+/, $escon_list[$line]); 
               if ($methods) {
                   ($tecserver, $method, $source, $class) = split(/:/, $methods);
               }
         }
      }
$line++;
}

($rcflag) && print("$rcflag\n") || print("0\n");

########################################################################
## Sub     : chk_escon                                                 #
## Purpose : Check escon status                                        #
## Usage   : chk_escon($devive)                                        #
##           1) escon name                                             #
## Return  : 1 if escon channel down                                   #
########################################################################

sub chk_escon {
    my ($escon_ch) = @_;
    my ($pu,$session, $teststatus, $msg);


    $teststatus = 1;
    open(OUTPUT, 'sna -d l |');
    while (<OUTPUT>) {
      if ( (/$escon_ch/) && (/Active/)) {
         ($pu, undef, undef, undef, ,undef, $session, undef) = split(/[\t \n]+/);
         $msg = $escon_ch." is Active, numb session = ".$session;
      }
    }
    close OUTPUT;

#    if ( ($msg =~ /Active/) && ($session != 0) ) {
#        $teststatus = 0;
#    }

    if ($msg =~ /Active/) {
        $teststatus = 0;
    }

    return ($teststatus);

}



#########################################################################
## Sub     : getlocalenv                                                #
## Purpose : Return local environ variableis to the program             #
## Usage   : getlocalenv()                                              #
#########################################################################

sub getlocalenv {
    
    $path = $dm_env->{'path'};
    $path_src = $dm_env->{'path_src'};
    $eventlog = $dm_env->{'eventlog'};
    $tecserver = $dm_env->{'tecserver'};
    $armvalue  = $dm_env->{'armvalue'};

    return(0);

}

sub getresenv {
   
   $class   = $res_env->{'class'};
   $source  = $res_env->{'source'};
   $method  = $res_env->{'method'};
   $evtlockfile = $res_env->{'evtlockfile'};
   
   $lockfile = $path."$evtlockfile";

   return(0);
}

sub gettecenv {
  
   $sevtec{'f'} = $tec_env->{'f'};
   $sevtec{'c'} = $tec_env->{'c'};
   $sevtec{'w'} = $tec_env->{'w'};
   $sevtec{'u'} = $tec_env->{'u'};
   $sevtec{'m'} = $tec_env->{'m'};
   $sevtec{'h'} = $tec_env->{'h'};

   return(0);
}

