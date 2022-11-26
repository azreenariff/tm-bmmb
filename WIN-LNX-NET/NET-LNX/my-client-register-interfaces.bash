#!/bin/bash

#-- Variable Settings

#-- Set current directory
me=`whoami`
pwd > /tmp/$me-kpu-currentdir
MYPWD=$( cat /tmp/$me-kpu-currentdir )
export MYPWD
#------------------------
MYNAGIOSHOME=/usr/local/nagios
export MYNAGIOSHOME
mycfgdir=$MYPWD/mycfgdir
myhostlist=$MYPWD/myhostlist
myostypelist=$MYPWD/myostypelist

#--------------------

contornot(){
  [[ "$MYABORT" = "1" ]] && return 0
  MYABORT=0
  cd $MYPWD
  answer="None"
  while ! [[ "$answer" =~ ^(Y|y|yes|Yes|N|n|no|No)$ ]] 
  do
      read -p "Do you want to continue (y/n)? " answer
  done 
}

#--- Initial Checks

if [ ! -w $mytemplatedir ]; then
  echo "";echo "WARNING: $mytemplatedir does not exist!";echo ""
  contornot
  if [[ "$answer" == "N" || "$answer" == "n" || "$answer" == "no" || "$answer" == "No" ]]; then
    echo ""; echo "Aborted."; echo ""; exit 0
  fi
fi

if [ ! -s $myostypelist ]; then
  echo "";echo "ERROR: Cannot find required OS type list $myostypelist. Unable to proceed.";echo "";exit 1
fi

if [ ! -s $myhostlist ]; then
  echo "";echo "ERROR: Cannot find required hosts list $myhostlist. Unable to proceed.";echo "";exit 1
fi

if [ ! -s $myhostinitconf ]; then
  echo "";echo "ERROR: Cannot find required host init config file $myhostinitconf. Unable to proceed.";echo "";exit 1
fi

if [ ! -d $mycfgdir ]; then
  mkdir $mycfgdir
fi

#------------------

#-- Functions

MYPAUSE(){
echo ""
echo "Press [Enter] to continue."
read -e MYCHECK
MYCHECK=0
}

MYINPUTERR(){
echo "Incorrect response, hit [ENTER] to continue"
read -e MYRET
}

config-error(){
echo ""
echo "$(tput setaf 3)$(tput setab 1)$(tput bold)$(tput blink)Applying configuration had Errors!... exiting.$(tput sgr0)"
echo ""
exit
}
kpu-reconfigure(){
${MYNAGIOSHOME}xi/scripts/reconfigure_nagios.sh || config-error
wait
sleep 1
}

MY_ADDS(){
if [ -f $mycfgfile ]; then
  /usr/bin/cp -fp $mycfgfile ${MYNAGIOSHOME}/etc/import
  chown apache.nagios ${MYNAGIOSHOME}/etc/import/*
  kpu-reconfigure
fi
cd $MYPWD
}

MY_ADDSNOAPPLY(){
if [ -f $mycfgfile ]; then
  /usr/bin/cp -fp $mycfgfile ${MYNAGIOSHOME}/etc/import
  chown apache.nagios ${MYNAGIOSHOME}/etc/import/*
fi
cd $MYPWD
}

MY_DO_ADDINTERFACES(){
cd $MYPWD

##-- Extract hostname & ip address from listing
myhostname=`echo $i | cut -d: -f1`;myipaddr=`echo $i | cut -d: -f2`

if ! ping -c 3 ${myipaddr} &> /dev/null; then
  echo "${myipaddr} - cannot ping!"
  return
fi

echo ""; echo  "$(tput setaf 0)$(tput setab 3)Adding interfaces for ${myhostname}$(tput sgr0)"

if [ ! -d confint ]; then
  mkdir confint
fi

#-- Add Interfaces
mycfgfile=$MYCLIENT-$MYOSGEN-INTERFACES-$MYAGENT.cfg
[[ "$MYAGENT" == "NCPA" ]] && curl -k https://${myipaddr}:5693/api/interface?token=${mytokenreal} | grep '{' | grep -v ^'{' | grep -v 'interface' | grep -v 'lo' | grep -v 'Ethernet Instance' | grep -v 'Loopback' | cut -d ':' -f1 | tr -d '"' | sed -e 's/^[ \t]*//' > confint/${myhostname}-intout
if ! grep -q '[^[:space:]]' "confint/${myhostname}-intout"; then
  echo ""; echo  "$(tput setaf 0)$(tput setab 3)Unable to acquire interfaces for ${myhostname}!$(tput sgr0)";echo ""
else
  IFS=$'\n'
  myintarr=(`cat confint/${myhostname}-intout`)
  for myint in "${myintarr[@]}"; do
    myintonly=$(echo ${myint} | sed 's/ //g') 

    ###>>> IF TEMPORARY FILE DOESN'T EXIST <<<###
    if [ ! -s confint/temp-myint-${myintonly}-${mycfgfile} ]; then

      ###>>> CHECK IF INTERFACES ALREADY EXIST AND MONITORED FOR HOST IN SERVICE FILE <<<###
      if ! sed -n "/define service {/{:a;N;/}/!ba; /$myint Bandwidth -/p}" /usr/local/nagios/etc/services/${mycfgfile} 2> /dev/null | grep ${myhostname}; then
        echo "Interface ${myint} not monitored yet... adding"

        ###>>> IF NOT, SNIP INTERFACE PART INTO TEMPORARY FILE <<<###
        sed -n "/define service {/{:a;N;/}/!ba; /$myint Bandwidth -/p}"  /usr/local/nagios/etc/services/${mycfgfile} > confint/temp-myint-${myintonly}-${mycfgfile} 2> /dev/null

        ###>>> IF FAIL, COPY TEMPLATE INTO TEMPORARY FILE <<<###
        if [ $? -ne 0 ]; then
          echo "Copying from template"
          /usr/bin/cp -fp myconfinit/$MYOSGEN-INTERFACES-$MYAGENT.cfg confint/temp-myint-${myintonly}-${mycfgfile}
        fi

      ###>>> ELSE, ADD HOST INTO TEMPORARY FILE <<<###
      else
        echo "Interface ${myint} already monitored, adding hostname ${myhostname} into temp file"
        sed  -i "/host_name/s/$/,${myhostname}/" confint/temp-myint-${myintonly}-${mycfgfile}
      fi
    fi

    ###>>> CHECK IF INTERFACE ALREADY EXIST AND MONITORED FOR HOST IN TEMPORARY FILE <<<###
    export myhostname
    envsubst '${myhostname},' < confint/temp-myint-${myintonly}-${mycfgfile} > confint/temp2-myint-${myintonly}-${mycfgfile}
    /usr/bin/cp -fp confint/temp2-myint-${myintonly}-${mycfgfile} confint/temp-myint-${myintonly}-${mycfgfile}
    if ! sed -n "/define service {/{:a;N;/}/!ba; /$myint Bandwidth -/p}" confint/temp-myint-${myintonly}-${mycfgfile} 2> /dev/null | grep ${myhostname}; then
      echo "${myhostname} is not found monitoring ${myint}... adding"

    ###>>> IF NOT, ADD HOST INTO TEMPORARY FILE <<<###
      sed  -i "/host_name/s/$/,${myhostname}/" confint/temp-myint-${myintonly}-${mycfgfile}
    fi

    ###>>> SUBSTITUE VARIABLES AND COPY INTO IMPORT FILE <<<###
    export myhostname myint myint
    envsubst '${myhostname},${myint},${myint}' < confint/temp-myint-${myintonly}-${mycfgfile} > confint/myint-${myintonly}-${mycfgfile}
    /usr/bin/cp -fp confint/myint-${myintonly}-${mycfgfile} confint/temp-myint-${myintonly}-${mycfgfile}
  done

  echo ""; echo  "$(tput setaf 0)$(tput setab 3)Completed adding interfaces for ${myhostname}$(tput sgr0)"

fi

}

#------------

#-- MAIN EXECUTION

echo ""
echo ""; echo  "$(tput setaf 3)$(tput setab 1)$(tput bold)$(tput blink)NOTE:$(tput sgr0)  Make sure you have installed $(tput setaf 0)$(tput setab 3)jq$(tput sgr0) !!!"
echo ""
contornot
if [[ "$answer" == "N" || "$answer" == "n" || "$answer" == "no" || "$answer" == "No" ]]; then
  echo ""; echo "Aborted."; echo ""; exit 0
fi

read -p "Enter your client abbreviation in one word: " MYCLIENT

# Set the NCPA token
. $MYPWD/mytoken
eval mytokenreal=${mytoken[i]}
cat /usr/local/nagios/etc/resource.cfg | grep USER11 > /dev/null
if [ $? -ne 0 ]; then
  echo '' >> /usr/local/nagios/etc/resource.cfg
  echo '# NCPA Token' >> /usr/local/nagios/etc/resource.cfg
  MYUSER='$USER11$'
  MYSTRING="${mytoken}"
  MYRESOURCE="${MYUSER}=${mytoken}"
  echo "${MYRESOURCE}" >> /usr/local/nagios/etc/resource.cfg
  echo '' >> /usr/local/nagios/etc/resource.cfg
fi

# Add Disk Services
MYDOIT=0
for j in $( grep -v '^#' ${myostypelist} ); do
  myoutfile=$mycfgdir/$MYCLIENT-$j-list
  awk "/--start-$j--/{flag=1; next} /--end-$j--/{if (flag == 1) exit} flag" $myhostlist > $myoutfile
  case $j in
    AIX)
      MYHG="$j"
      MYOSGEN="$j"
      MYAGENT="NCPA"
      MYDOIT=1
    ;;
    SOLARIS)
      MYHG="$j"
      MYOSGEN="$j"
      MYAGENT="NCPA"
      MYDOIT=1
    ;;
    LINUX)
      MYHG="$j"
      MYOSGEN="$j"
      MYAGENT="NCPA"
      MYDOIT=1
    ;;
    WINDOWS)
      MYHG="$j"
      MYOSGEN="$j"
      MYAGENT="NCPA"
      MYDOIT=1
    ;;
    SUSE)
      MYHG="$j"
      MYOSGEN="$j"
      MYAGENT="NCPA"
      MYDOIT=1
    ;;
    *)
      MYHG="$j"
      MYOSGEN="$j"
      MYAGENT="NCPA"
      MYDOIT=0
    ;;
  esac
  if [[ $MYDOIT -eq 1 ]]; then 
    rm -rf $MYPWD/confiles 2> /dev/null
    for i in $( grep -v '^#' ${myoutfile} ); do
      [ "$i" ] && echo ""; MY_DO_ADDINTERFACES
    done
    cd $MYPWD/confint
    cat myint-*-${mycfgfile} >> ${mycfgfile}
    MY_ADDS
  fi
done

rm -rf $MYPWD/confiles
rm -rf $MYPWD/confint
rm -rf $MYPWD/mycfgdir

echo ""
echo "ALL COMPLETED!!!"
echo ""

