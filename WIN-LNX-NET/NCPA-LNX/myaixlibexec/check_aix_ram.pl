#!/usr/bin/perl

use Getopt::Long;
&Getopt::Long::config('auto_abbrev');

my $numbarg = @ARGV;
($numbarg < 2) && &show_help;

my %STATUSCODE = (  'UNKNOWN' => '-1',
                    'OK' => '0',
                    'WARNING' => '1',
                    'CRITICAL' => '2');


sub show_help {
    printf("usage: ./check_aix_ram.pl -w # -c #\n
Options:
        -w warning threshold (%)
        -c critical threshold (%)

");
    exit($STATUSCODE{"UNKNOWN"});
}


$status = GetOptions( "warn=s",	\$warn,
                      "crit=i",	\$crit);


$usage = system("svmon | grep memory | awk '{print ($3/$2)*100}'");

printf("$usage\n");

if ($usage >= $crit) {

	printf("CRITICAL - RAM usage at $usage%\n");
	exit($STATUSCODE{"CRITICAL"});
	}

elsif ($usage >= $warn) {

	printf("WARNING - RAM usage at $usage%\n");
	exit($STATUSCODE{"WARNING"});
	}

elsif ($usage < $warn) {

	printf("OK - RAM usage at $usage%\n");
	exit($STATUSCODE{"OK"});
	}

else {
	printf("UNKNOWN - unable to determin usage\n");
	 exit($STATUSCODE{"UNKNOWN"});
	}

