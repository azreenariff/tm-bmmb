#!/bin/sh
#
#-------------------------------------------------------
# Chequeo de uso de cada CPU - Mario Giacummo - 18/09/07
#-------------------------------------------------------
#-------------------------------------------------------
Sintaxis() {
   echo " "
   echo "  Command Sintax: check_aix_paging.sh [-c val] [-w val]"
   echo " "
   exit 3;
}
#-------------------------------------------------------

  if [[ $# == 0 ]] 
  then
    Sintaxis
  fi
  valw=0
  valc=0
  while [[ $# > 0 ]]
  do
     par=$1
     case $par in
       -c) shift
           valc=$1;;
       -w) shift
           valw=$1;;
       -h) shift
           Sintaxis
           exit;;
        *) shift;;
     esac
  done

ok=0
str_out="Paging:"
valp=`lsps -s | tail -1 | awk '{print $2}' | cut -d "%" -f1`
if (( $valp > $valc ))
then
   str_out=$str_out" CRITICAL ($valp)"
   ok=2 
else
  if (( $valp > $valw ))
  then
     str_out=$str_out" WARNING ($valp)"
     ok=1 
  else
     str_out=$str_out" OK ($valp)"
  fi
fi
echo $str_out"%"
exit $ok
