#!/bin/ksh

# Nagios Exit Codes
OK=0
WARNING=1
CRITICAL=2
UNKNOWN=3

# Check errpt for PERM Errors

errpt=/usr/bin/errpt
checkerrpt=`${errpt} -T PERM`

if [ -z "${checkerrpt}" ]; then
  echo "OK: No Errors"
  exit $OK;
else
  echo "WARNING: The are Errors!\n${checkerrpt}"
  exit $WARNING;
fi

