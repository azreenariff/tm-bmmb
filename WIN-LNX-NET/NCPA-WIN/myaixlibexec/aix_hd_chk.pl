#!/usr/bin/perl -w

#############################################################################
# Programe : aix_hd_chk.pl                                                   #
# Version  : 3.6                                                             #
# Author   : Near Him Lim                                                    #
# Company  : Royal Bank of Canada                                            #
# Dept     : CN&S                                                            #
# Date     : 98 Feb 06                                                       #
# Env      : Perl5_004_01                                                    #
# Purpose  : Check for Hardware problem reported in errlog                   # 
# Usage    : aix_hd_chk.pl <hardware_confile>                                #
# Return   : None                                                            #
# History  :  - Allow the problem to read hardware item to check from        #
#               the user configuration file   - Mars 15 1998 (NHL)           #
#             - Allow user to add severity in the hardware                   #
#               configuration file                                           # 
##############################################################################

require dmenv;
require dmlib;

my $numbarg = @ARGV;
($numbarg != 1) && die("Usage: $0 <hdw_config_file>\n");

my ($path, $path_src, $eventlog, $actionlog, $tecserver, $method);
my (%sevtec, $host, $class, $source, $evtlockfile);
my (@hdwlist, @desc1, $thedate, $mydate, $lastdate, $timestamp, $resname);

#
# Create object classes to allow access to Tivoli/RBC environment variables
#
my $dm_env  = getlocal_dm_env dmenv();
my $tec_env = getlocal_tec_env dmenv();
my $res_env = getlocal_res_env dmenv('class'    => 'Pstmsg_hdw',
                                     'source'   => 'VVPOST',
                                     'method'   => 'postemsg',
                                     'evtlockfile' => 'evtlock'); 

&getlocalenv;
&getresenv;
&gettecenv;

#
# Create an object class dmlib to allow access to Tivoli/RBC library
#
my $sub = new dmlib;
$host=dmlib::gethost($sub);

#
# Place to store the next date and time
# to read from the errlog file
#
my $datefile = $path."date.txt";

#
# Read hardware configuration file
# and store on an internal list hdwlist.
#
my $hdconfile = shift(@ARGV);
open(CONFIGFILE, "$hdconfile") || die("Cannot read hardware config file $hdconfile\n");
@hdwlist = <CONFIGFILE>;
close (CONFIGFILE);

$mydate = `date +%m%d%H%M%y`;

#chop($mydate);


#
# Open the date file, and read the date information 
# If no date in the date file, then use the current date
#
open(DATEFILE, "$datefile") || open(DATEFILE, ">$datefile") || die("Cannot create $datefile\n");
$thedate = <DATEFILE>;
close (DATEFILE);

($thedate = $mydate) if !(defined $thedate);
#
# Invoke errpt command starting from $thedate
#
open(INCOMING, "/usr/bin/errpt -s $thedate |");
#open(INCOMING, 'cat /tmp/errpt.txt |');
my $i = 1;
while (<INCOMING>) {
      if ($i > 1 ) {
          (undef, $timestamp, undef, undef, $resname, @desc1) = split(/[\t \n]+/);
          ( $i == 2 ) && ($lastdate = $timestamp);
          ($timestamp != $thedate) && &chk_hdw($resname, $timestamp, @desc1);
          ($timestamp == $thedate) && &chk_hdw($resname, $timestamp, @desc1);
      }
      $i++;
}
close (INCOMING);

#
#  Write to the datefile, the next date for the next errpt call 
#
open(DATEFILE, ">$datefile") || die("Cannot $datefile\n");
($lastdate = $mydate) if !(defined $lastdate);
print DATEFILE ($lastdate);
close (DATEFILE);

print("0\n");
#################################################################
sub chk_hdw {
    my ($hdname, $timedate, @desc) = @_;
    my ($message, $armfile, $ckhdate, $f_day, $c_day, $k, @tmp);

    #
    # Check the device name against the user defined hardware list
    # In the user hardware list, the full name of the device
    # is not required !
    # Example: To check for disk problem, just enter disk or hd.
    #          The script will pick up hdisk3, hdisk2 etc ... and
    #          hd1, hd2 etc.....
    #
    $k = 0;
    while ( $k <= $#hdwlist ) {
          @tmp = split(/[: \t \n]+/, $hdwlist[$k]);
          if ( $hdname =~ /$tmp[0]/ ) {
               $armfile = $path."$hdname".".hdt";
               last;
          }
     $k++;
    }

# Send TEC event if the hardware problem has been detected for the first
# time. If the same problem occurs the same days, no event will sent out.
# The same event will send out again (if it ocuured) the next day.
# This method will ensure that the network and the TEC database won't
# flooded.

    # if ( ($armfile ne '') && !(-e $armfile) ) {
    if ( ($armfile) && !(-e $armfile) ) {
       $message = "Error on $hdname: @desc";
      
       dmlib::send_alert($sub, $message, $hdname, $method, $sevtec{$tmp[1]}, $class,
                         $source, $host, $path_src, $eventlog, $evtlockfile, $tecserver);
       (open(OUTFILE, ">$armfile")) || die("Cannot open $armfile\n");
       print OUTFILE ($timedate);
       close (OUTFILE);

    }
    else {
          if (($armfile) && (-e $armfile) ) {

             (open(OUTFILE, "$armfile")) || die("Cannot open $armfile\n");
             $chkdate = <OUTFILE>;
             close (OUTFILE); 
             #
             # Let's cook
             # Send the same event again the next day
             #
             $f_day = substr($chkdate, 2, 2);
             $c_day = substr($timedate, 2, 2);
             if ( $f_day ne $c_day ) {
                 $message = "Error on $hdname: @desc";

                 dmlib::send_alert($sub, $message, $hdname, $method, $sevtec{$tmp[1]}, $class,
                                    $source, $host, $path_src, $eventlog, $evtlockfile, $tecserver);



                 open(OUTFILE, ">$armfile") || die("Cannot create $armfile\n"); 
                 print OUTFILE ($timedate);
                 close(OUTFILE);
             }

          } 
    }
    
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

    return(0);

}

sub getresenv {
   
   $class   = $res_env->{'class'};
   $source  = $res_env->{'source'};
   $method  = $res_env->{'method'};
   $evtlockfile = $res_env->{'evtlockfile'};
   
   $evtlockfile = $path."$evtlockfile";

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

