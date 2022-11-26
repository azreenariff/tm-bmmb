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
mysvcdir=/usr/local/nagios/libexec
mytemplatedir=$MYPWD/templates
mycfgdir=$MYPWD/mycfgdir
myhostlist=$MYPWD/myhostlist
myostypelist=$MYPWD/myostypelist
myhostinitconf=$MYPWD/myconfinit/host-addconfig

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

echo ""; echo  "$(tput setaf 3)$(tput setab 1)$(tput bold)$(tput blink)NOTE:$(tput sgr0)  Make sure you have installed the $(tput setaf 0)$(tput setab 3)check_nwc_health$(tput sgr0) plugin and Perl modules $(tput setaf 0)$(tput setab 3)File::Slurp$(tput sgr0) and $(tput setaf 0)$(tput setab 3)JSON::XS$(tput sgr0) !!!"
contornot
if [[ "$answer" == "N" || "$answer" == "n" || "$answer" == "no" || "$answer" == "No" ]]; then
  echo ""; echo "Aborted."; echo ""; exit 0
fi

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

MY_ADD_PLUGINS(){
#-- Add new plugins
if [ -d $MYPWD/mylibexec ]; then
  chown -R apache:nagios $MYPWD/mylibexec/*
  cp -rfp $MYPWD/mylibexec/* /usr/local/nagios/libexec/
fi
}

MY_ADD_NEWCOMMANDS(){
#-- Add new commands
if [ -d $MYPWD/templates ]; then
  mycfgfile=commands.cfg
  cd $MYPWD/templates 
  MY_ADDS
  echo ""; echo "New commands added."; echo ""
fi
}

MY_ADD_CONTACTS(){
#-- Add Contacts
if [ -d $MYPWD/templates ]; then
  mycfgfile=contacts.cfg
  cd $MYPWD/templates 
  MY_ADDS
  echo ""; echo "New contacts added."; echo ""
fi
}

MY_ADD_CONTACTGRPS(){
#-- Add Contact Groups
if [ -d $MYPWD/templates ]; then
  mycfgfile=contactgroups.cfg
  cd $MYPWD/templates 
  MY_ADDS
  echo ""; echo "New contact groups added."; echo ""
fi
}

MY_ADD_HOSTGRPS(){
#-- Add Host Groups
if [ -d $MYPWD/templates ]; then
  mycfgfile=hostgroups.cfg
  cd $MYPWD/templates 
  MY_ADDS
  echo ""; echo "New host groups added."; echo ""
fi
}

MY_DO_ADDHOST(){
cd $MYPWD

##-- Extract hostname & ip address from listing
myhostname=`echo $i | cut -d: -f1`;myipaddr=`echo $i | cut -d: -f2`

if [ ! -d confiles ]; then
  mkdir confiles
fi

export myhostname; export myipaddr; export j; export iconimage

#-- Add New Hosts
cd $MYPWD
envsubst '${myhostname},${j},${myipaddr},${iconimage}' < $myhostinitconf > confiles/${myhostname}.cfg
mycfgfile=${myhostname}.cfg
cd $MYPWD/confiles
MY_ADDSNOAPPLY

cd $MYPWD/confiles
MY_ADDSNOAPPLY

}

MY_DO_ARGNEWHOST(){
cd $MYPWD

##-- Extract hostname & ip address from listing
myhostname=`echo $i | cut -d: -f1`;myipaddr=`echo $i | cut -d: -f2`
export myhostname; export myipaddr; export j; export iconimage

MYHOSTarr+=(${myhostname})
printf -v MYHOSTALL '%s,' "${MYHOSTarr[@]}"

}

MY_DO_ADDMONITOR(){
cd $MYPWD

myhostname=$( echo "${MYHOSTALL%,}" )

if [ ! -d confiles ]; then
  mkdir confiles
fi

#-- Add New Standard Services
cd $MYPWD
mycfgfile=$MYCLIENT-$MYOSGEN-SERVICES-$MYAGENT.cfg
ls /usr/local/nagios/etc/services | grep ${mycfgfile} > /dev/null
if [ $? -eq 0 ]; then
  cd $MYPWD/confiles
  cp -fp /usr/local/nagios/etc/services/${mycfgfile} .
  sed -i "/host_name/s/$/,${myhostname}/" ${mycfgfile}
  cd $MYPWD
else
  envsubst '${myhostname}' < $MYPWD/myconfinit/$MYOSGEN-SERVICES-$MYAGENT.cfg > confiles/${mycfgfile}
fi
cd $MYPWD/confiles
MY_ADDSNOAPPLY

}

MY_DO_ADDHOSTGRP(){
cd $MYPWD

##-- Extract hostname & ip address from listing
myhostname=`echo $i | cut -d: -f1`;myipaddr=`echo $i | cut -d: -f2`

if [ ! -d confiles ]; then
  mkdir confiles
fi

export myhostname; export myipaddr; export j; export iconimage

#-- Add into hostgroups
cd $MYPWD

if [ -s confiles/hostgroups.cfg ]; then
    sed -i "/members/s/$/,${myhostname}/" confiles/hostgroups.cfg
elif grep -q "hostgroup_name.*${j}" /usr/local/nagios/etc/hostgroups.cfg; then
  if ! grep -q "members.*${myhostname}" /usr/local/nagios/etc/hostgroups.cfg; then
    grep -B 1 -A 3 "hostgroup_name.*${j}" /usr/local/nagios/etc/hostgroups.cfg > confiles/hostgroups.cfg
    sed -i "/members/s/$/,${myhostname}/" confiles/hostgroups.cfg
  fi
else
  cat << EOF > confiles/hostgroups.cfg
define hostgroup {
    hostgroup_name    ${j}
    alias             ${j} HOSTS
    members           ${myhostname}
}

EOF
fi

cd $MYPWD/confiles
mycfgfile=hostgroups.cfg
MY_ADDSNOAPPLY

}

#------------

#~~~~~~~~~~~~~~~~~~~~#
#-- MAIN EXECUTION --#
#~~~~~~~~~~~~~~~~~~~~#

echo ""
read -p "Enter your client abbreviation in one word: " MYCLIENT

answer="None"
read -p "Is this First time run (y/n)? " answer
case ${answer:0:1} in
    n|N )
        echo "Ok, skipping adding plugins, new commands, contacts and contactgroups."
    ;;
    * )
        MY_ADD_PLUGINS
        MY_ADD_NEWCOMMANDS
        MY_ADD_CONTACTS
        MY_ADD_CONTACTGRPS
    ;;
esac

# Add Standard Services
cat /usr/local/nagios/etc/resource.cfg | grep USER10 > /dev/null
if [ $? -ne 0 ]; then
  . $MYPWD/mysnmpcomstring
  echo '' >> /usr/local/nagios/etc/resource.cfg
  echo '# Network Device SNMP Community String' >> /usr/local/nagios/etc/resource.cfg
  MYUSER='$USER10$'
  MYSTRING="${mysnmpcomstring}"
  MYRESOURCE="${MYUSER}=${mysnmpcomstring}"
  echo "${MYRESOURCE}" >> /usr/local/nagios/etc/resource.cfg
  echo '' >> /usr/local/nagios/etc/resource.cfg
fi
for j in $( grep -v '^#' ${myostypelist} ); do
  myoutfile=$mycfgdir/$MYCLIENT-$j-list
  awk "/--start-$j--/{flag=1; next} /--end-$j--/{if (flag == 1) exit} flag" $myhostlist > $myoutfile
  case $j in
    NETWORK)
      MYHG="$j"
      MYOSGEN="$j"
      MYAGENT="SNMP"
      iconimage="network_node.png"
    ;;
    SWITCHES)
      MYHG="$j"
      MYOSGEN="$j"
      MYAGENT="SNMP"
      iconimage="network_node.png"
    ;;
    ROUTERS)
      MYHG="$j"
      MYOSGEN="$j"
      MYAGENT="SNMP"
      iconimage="network_node.png"
    ;;
    FIREWALLS)
      MYHG="$j"
      MYOSGEN="$j"
      MYAGENT="SNMP"
      iconimage="network_node.png"
    ;;
    LOADBLANCERS)
      MYHG="$j"
      MYOSGEN="$j"
      MYAGENT="SNMP"
      iconimage="network_node.png"
    ;;
    NETAPPLIANCES)
      MYHG="$j"
      MYOSGEN="$j"
      MYAGENT="SNMP"
      iconimage="network_node.png"
    ;;
    *)
      MYHG="$j"
      MYOSGEN="$j"
      MYAGENT="SNMP"
      iconimage="network_node.png"
    ;;
  esac

  echo ""; echo  "$(tput setaf 0)$(tput setab 3)Adding hosts$(tput sgr0)"
  rm -rf $MYPWD/confiles 2> /dev/null
  for i in $( grep -v '^#' ${myoutfile} ); do
    [ "$i" ] && echo ""; MY_DO_ADDHOST
  done
  kpu-reconfigure
  echo  "$(tput setaf 0)$(tput setab 3)Adding hosts completed$(tput sgr0)"

  rm -rf $MYPWD/confiles 2> /dev/null
  MYHOSTarr=()
  for i in $( grep -v '^#' ${myoutfile} ); do
    [ "$i" ] && echo ""; MY_DO_ARGNEWHOST
  done

  echo ""; echo  "$(tput setaf 0)$(tput setab 3)Adding services$(tput sgr0)"
  rm -rf $MYPWD/confiles 2> /dev/null
  echo ""
  MY_DO_ADDMONITOR
  kpu-reconfigure
  echo  "$(tput setaf 0)$(tput setab 3)Adding services completed$(tput sgr0)"

  echo ""; echo  "$(tput setaf 0)$(tput setab 3)Adding hostgroup$(tput sgr0)"
  rm -rf $MYPWD/confiles 2> /dev/null
  for i in $( grep -v '^#' ${myoutfile} ); do
    [ "$i" ] && echo ""; MY_DO_ADDHOSTGRP
  done
  kpu-reconfigure
  echo  "$(tput setaf 0)$(tput setab 3)Adding hostgroup completed$(tput sgr0)"

done

rm -rf $MYPWD/confiles
rm -rf $MYPWD/confdisk
rm -rf $MYPWD/mycfgdir

echo ""
echo "ALL COMPLETED!!!"
echo ""

