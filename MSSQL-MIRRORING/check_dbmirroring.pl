#!/usr/bin/perl -w 

use strict;
use Getopt::Long;
use DBI;

# Nagios specific

#use lib "/usr/lib/nagios/plugins";
use lib "/usr/lib64/nagios/plugins";
use utils qw(%ERRORS $TIMEOUT);
#my $TIMEOUT = 15;
#my %ERRORS=('OK'=>0,'WARNING'=>1,'CRITICAL'=>2,'UNKNOWN'=>3,'DEPENDENT'=>4);


my $o_host;
my $o_db;
my $o_user="sa";
my $o_pw="";
my $name="";
my $state="";
my $role="";

sub print_usage {
    print "\n";
    print "Usage: check_dbmirroring.pl -H <host> -d <database> [-u <username>] [-p <password>] \n";
    print "\n";
    print "\tDefault Username is 'sa' without a password\n\n";
    print "\tScript should be run on the PRINCIPAL with a read-only user\n";
    print "\tIf you want to run it on the MIRROR, the user MUST have SYSADMIN rights on the SQL-Server\n";
    print "\totherwise you get NULL\n";
    print "\n";
}

sub check_options {
    Getopt::Long::Configure ("bundling");
    GetOptions(
        'H:s'   => \$o_host,
        'd:s'   => \$o_db,
        'u:s'   => \$o_user,
        'p:s'   => \$o_pw,
        );
    if (!defined ($o_host) || !defined ($o_db)) { print_usage(); exit $ERRORS{"UNKNOWN"}};
}

########## MAIN #######

check_options();

my $exit_val;

# Connect to database
my $dbh = DBI->connect("dbi:Sybase:server=$o_host:1433","$o_user","$o_pw") or exit $ERRORS{"UNKNOWN"};

my $sth=$dbh->prepare("SELECT d.name, m.mirroring_role_desc, m.mirroring_state_desc
                       FROM sys.database_mirroring m
                       JOIN sys.databases d ON m.database_id = d.database_id
                       WHERE mirroring_state_desc IS NOT NULL AND name = '$o_db'");
$sth->execute;

while (my @row = $sth->fetchrow_array) {
         $name=$row["0"];
         $role=$row["1"];
        $state=$row["2"];
}

$exit_val=$ERRORS{"CRITICAL"};
$exit_val=$ERRORS{"OK"} if ( $role eq "PRINCIPAL" ) && ( $state eq "SYNCHRONIZED" );


print "OK - $name - $role - $state\n"        if ($exit_val eq $ERRORS{"OK"});
print "CRITICAL - Check your mirroring settings\n" if ($exit_val eq $ERRORS{"CRITICAL"});
exit $exit_val;

