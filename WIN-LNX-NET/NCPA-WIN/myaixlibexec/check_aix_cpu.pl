#!/usr/bin/perl

use Getopt::Long;
&Getopt::Long::config('auto_abbrev');

my $cpuno = `vmstat | grep lcpu | cut -c 47-49`;
my $cpu = ("$cpuno CPU");
$cpu =~ s/\n//g;
my $numbarg = @ARGV;
($numbarg < 2) && &show_help;

my %STATUSCODE = (  'UNKNOWN' => '-1',
                    'OK' => '0',
                    'WARNING' => '1',
                    'CRITICAL' => '2');


sub show_help {
    printf("usage: ./check_aix_cpu.pl -w # -c #\n
Options:
        -w warning threshold (%)
        -c critical threshold (%)

");
    exit($STATUSCODE{"UNKNOWN"});
}


$status = GetOptions( "warn=s", \$warn,
                      "crit=i", \$crit);


open(PS, "/usr/bin/vmstat 1 4 | egrep -v '[a-z,A-Z]|-' |egrep '[0-9]' |") || return 1;
        while (<PS>) {
                (undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,$idle,undef) = split(/[\t \n]+/);
                $tidle = $tidle + $idle;
               }
$usage = 100 - ($tidle / 4);

if ($usage >= $crit) {

        printf("CRITICAL - CPU usage at $usage%\n");
        exit($STATUSCODE{"CRITICAL"});
        }

elsif ($usage >= $warn) {

        printf("WARNING - CPU usage at $usage%\n");
        exit($STATUSCODE{"WARNING"});
        }

elsif ($usage < $warn) {

        printf("OK - CPU usage at $usage%. $cpu\n");
        exit($STATUSCODE{"OK"});
        }

else {
        printf("UNKNOWN - unable to determine usage\n");
         exit($STATUSCODE{"UNKNOWN"});
        }

