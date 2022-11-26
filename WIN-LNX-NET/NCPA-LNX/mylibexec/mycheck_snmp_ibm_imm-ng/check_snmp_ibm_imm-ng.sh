#!/bin/sh

#
# This is a script for monitoring sensors (temperature, fans and voltage) and 
# overall health of IBM servers using SNMPv1 to the Integrated Management Module (IMM).
#

# Version 0.4 2017-10-11
#Added a 5 second timeout to snmpwalk instead of the default of one.
# Fixed a bug with the exit status for help.

# Version 0.3 2017-10-09
# Farid Joubbi farid@joubbi.se
# Added warning and critical level to temperature performance data.
# Added label for performance data instead of just a number.
# Added check for 0 in critical temperature.
# Removed ofmaximum from fan speed output for nicer performance graphs.
# Renamed offline to zero in performance data for fans.


# Version 0.0.2 2010-08-24
# Return 3 for unknown results.

# Version 0.0.1 2010-05-21
# Ulric Eriksson <ulric.eriksson@dgc.se>

SNMPWALK="/usr/bin/snmpwalk"

BASEOID=.1.3.6.1.4
IMMOID=$BASEOID.1.2.3.51.3

tempOID=$IMMOID.1.1
tempsOID=$tempOID.1.0
# Temperature sensor count
tempIndexOID=$tempOID.2.1.1
# Temperature sensor indexes
tempNameOID=$tempOID.2.1.2
# Names of temperature sensors
tempTempOID=$tempOID.2.1.3
tempFatalOID=$tempOID.2.1.5
tempCriticalOID=$tempOID.2.1.6
tempNoncriticalOID=$tempOID.2.1.7

voltOID=$IMMOID.1.2
voltsOID=$voltOID.1.0
voltIndexOID=$voltOID.2.1.1
voltNameOID=$voltOID.2.1.2
voltVoltOID=$voltOID.2.1.3
voltCritHighOID=$voltOID.2.1.6
voltCritLowOID=$voltOID.2.1.7

fanOID=$IMMOID.1.3
fansOID=$fanOID.1.0
fanIndexOID=$fanOID.2.1.1
fanNameOID=$fanOID.2.1.2
fanSpeedOID=$fanOID.2.1.3
fanMaxSpeedOID=$fanOID.2.1.8

healthStatOID=$IMMOID.1.4
# 255 = Normal, 0 = Critical, 2 = Non-critical Error, 4 = System-level Error

# 'label'=value[UOM];[warn];[crit];[min];[max]

usage()
{
	echo "Usage: $0 -H host -C community -T health|temperature|voltage|fans"
}

get_health()
{
	echo "$HEALTH"|grep "^$1."|head -1|sed -e 's,^.*: ,,'|tr -d '"'
}

get_temperature()
{
        echo "$TEMP"|grep "^$2.*$1 = "|head -1|sed -e 's,^.*: ,,'|tr -d '"'
}

get_voltage()
{
        echo "$VOLT"|grep "^$2.*$1 = "|head -1|sed -e 's,^.*: ,,'|tr -d '"'
}

get_fan()
{
        echo "$FANS"|grep "^$2.*$1 = "|head -1|sed -e 's,^.*: ,,'|tr -d '"'
}

if test "$1" = -h; then
	usage
        exit 0
fi

while getopts "H:C:T:" o; do
	case "$o" in
	H )
		HOST="$OPTARG"
		;;
	C )
		COMMUNITY="$OPTARG"
		;;
	T )
		TEST="$OPTARG"
		;;
	* )
		usage
                exit 3
		;;
	esac
done

SNMPOPTS=" -v 1 -c $COMMUNITY -On -t 5 $HOST"

RESULT=''
STATUS=0	# OK

case "$TEST" in
health )
	HEALTH=`$SNMPWALK $SNMPOPTS $healthStatOID`
	healthStat=`get_health $healthStatOID`
	case "$healthStat" in
	0 )
		RESULT="Health status: Critical"
		STATUS=2	# Critical
		;;
	2 )
		RESULT="Health status: Non-critical error"
		STATUS=1
		;;
	4 )
		RESULT="Health status: System level error"
		STATUS=2
		;;
	255 )
		RESULT="Health status: Normal"
                STATUS=0
		;;
	* )
		RESULT="Health status: Unknown"
		STATUS=3
		;;
	esac
	;;
temperature )
	TEMP=`$SNMPWALK $SNMPOPTS $tempOID`
	# Figure out which temperature indexes we have
	temps=`echo "$TEMP"|
	grep -F "$tempIndexOID."|
	sed -e 's,^.*: ,,'`
	if test -z "$temps"; then
		RESULT="No temperatures"
		STATUS=3
	fi
	for i in $temps; do
		tempName=`get_temperature $i $tempNameOID`
		tempTemp=`get_temperature $i $tempTempOID`
		tempFatal=`get_temperature $i $tempFatalOID`
		tempCritical=`get_temperature $i $tempCriticalOID`
		tempNoncritical=`get_temperature $i $tempNoncriticalOID`
		RESULT="$RESULT$tempName = $tempTemp
"
		if test "$tempCritical" -gt 0; then
			if test "$tempTemp" -ge "$tempCritical"; then
				STATUS=2
			elif test "$tempTemp" -ge "$tempNoncritical"; then
				STATUS=1
			fi
		fi
		PERFDATA="${PERFDATA}'$tempName'=$tempTemp;$tempNoncritical;$tempCritical;; "
	done
	;;
voltage )
	VOLT=`$SNMPWALK $SNMPOPTS $voltOID`
	volts=`echo "$VOLT"|
	grep -F "$voltIndexOID."|
	sed -e 's,^.*: ,,'`
	if test -z "$volts"; then
		RESULT="No voltages"
		STATUS=3
	fi
	for i in $volts; do
		voltName=`get_voltage $i $voltNameOID`
		voltVolt=`get_voltage $i $voltVoltOID`
		voltCritHigh=`get_voltage $i $voltCritHighOID`
		voltCritLow=`get_voltage $i $voltCritLowOID`
		RESULT="$RESULT$voltName = $voltVolt
"
		if test "$voltCritLow" -gt 0 -a "$voltVolt" -le "$voltCritLow"; then
			#echo "$voltVolt < $voltCritLow"
			STATUS=2
		elif test "$voltCritHigh" -gt 0 -a "$voltVolt" -ge "$voltCritHigh"; then
			#echo "$voltVolt > $voltCritLow"
			STATUS=2
		fi
		PERFDATA="${PERFDATA}'$voltName'=$voltVolt;;;; "
	done
	;;
fans )
	FANS=`$SNMPWALK $SNMPOPTS $fanOID`
	fans=`echo "$FANS"|
	grep -F "$fanIndexOID."|
	sed -e 's,^.*: ,,'`
	if test -z "$fans"; then
		RESULT="No fans"
		STATUS=3
	fi
	for i in $fans; do
		fanName=`get_fan $i $fanNameOID`
		fanSpeed=`get_fan $i $fanSpeedOID|tr -d 'h '| sed -e 's/ofmaximum//g'`
		RESULT="$RESULT$fanName = $fanSpeed
"
		fanSpeedPerf=`echo $fanSpeed | sed -e 's/offline/0/g'`
		PERFDATA="${PERFDATA}'$fanName'=$fanSpeedPerf;;;; "
	done
	;;
* )
	usage
        exit 3
	;;
esac

echo "$RESULT|$PERFDATA"
exit $STATUS
