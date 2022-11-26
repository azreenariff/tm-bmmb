#!/bin/sh
#
#-------------------------------------------------------
# Chequeo de uso de cada CPU - Mario Giacummo - 18/09/07
#-------------------------------------------------------
#-------------------------------------------------------
Sintaxis() {
   echo " "
   echo "  Command Sintax: check_aix_hdisk.sh [-c val] [-w val]"
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

str_out="Discos "
hdisks=`lspv | awk '{print $1}'`
for hd in $hdisks
do
  ocup=`iostat -d $hd | tail -1 | awk '{print $2}'`
  if (( $ok < 2 )) 
  then
    if (( $ocup > $valc ))
    then
      ok=2
      str_out=$str_out" $hd($ocup) "
    else
      if (( $ocup > $valw ))
      then
        ok=1
        str_out=$str_out" $hd($ocup) "
      fi
    fi
  fi
done
if (( $ok == 0 ))
then
   str_out=$str_out" OK "
fi
echo $str_out 
exit $ok
