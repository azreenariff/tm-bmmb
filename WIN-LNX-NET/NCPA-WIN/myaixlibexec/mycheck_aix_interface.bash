#!/usr/bin/bash

# Nagios Exit Codes
# -----------------
OK=0
WARNING=1
CRITICAL=2
UNKNOWN=3
# -----------------

mystatfile=/tmp/mystatfile
myoutfile=/tmp/myoutfile
touch $mystatfile
cat /dev/null > $mystatfile
touch $myoutfile
cat /dev/null > $myoutfile

for en in `ifconfig -l`; do
  if [[ $(ifconfig $en | grep UP) ]]; then
    echo "UP" >> $mystatfile
    echo -n "$en=UP " >> $myoutfile
  else
    echo "DOWN" >> $mystatfile
    echo -n "$en=DOWN " >> $myoutfile
  fi
done

RESULT=$(echo "`cat $myoutfile`")

if [[ $(grep DOWN $mystatfile) ]]; then 
  mystatus="Got a DOWN Net Interface"
  echo "CRITICAL: $RESULT"
  exit $CRITICAL;
else
  mystatus="All Net Interfaces are UP"
  echo "OK: $RESULT"
  exit $OK;
fi

