#!/bin/bash 
#
# check infrastructure status through hmc commands
#
#
# Date: 2013-06-12
# Version 0.9 beta
# Author: Ivan Bergantin - ITA
#
# Date: 2013-07-01
# Version 1.0 stable
# Author: Ivan Bergantin - ITA
# Revision: Fix and add cpu check
#

# get arguments

while getopts 'I:U:P:C:A:h' OPT; do
  case $OPT in
    I)  machine=$OPTARG;;
    U)  user=$OPTARG;;
    P)  password=$OPTARG;;
    C)  checkType=$OPTARG;;
    A)  myAttribute=$OPTARG;;
    *)  unknown="yes";;
  esac
done

# usage
HELP="
    Show info about IBM HMC (GPL licence)

    usage: $0 [ -I value -U value -P value -h ]

    syntax:

            -I --> IP Address
            -U --> User
            -P --> Password
            -C --> Check Type
		DETAILS    : show only the global details (without checks)
		ITEMSTATUS : check status of LPARs and SYSTEMs
		LEDSTATUS  : show led status
		UPTIMEHMC  : UpTime HMC
		UPTIMESYS  : UpTime Systems
		DISKHMC    : Check Disk usage on HMC
		HWEVENTS   : Check hardware events
		CPULPAR	   : Check cpu utilization
            -A --> Attribute
		DETAILS    : nothing
		ITEMSTATUS : Filter, put LPAR or System names separated by comma
		LEDSTATUS  : nothing
		UPTIMEHMC  : nothing
		UPTIMESYS  : nothing
		DISKHMC    : nothing
		HWEVENTS   : nothing
		CPULPAR	   : System Name

"

# se e' stato chiesto l'help col parametro -h o se non sono stati passati parametri ($# uguale a 0) stampo l'help
if [ "$hlp" = "yes" -o $# -lt 1 ]; then
	echo "$HELP"
	exit 0
fi

#############################
# FUNCTION
#############################

function filterObj {
	IFS=',' read -a objFilterArray <<< "$myAttribute"
	Fmax=${#objFilterArray[@]}
	exitFilter=0
	for (( j=0; j<$Fmax ; j++ ));
	do
		if [ "$1" = "${objFilterArray[$j]}" ]; then
			exitFilter=1
		fi
	done
	return $exitFilter
}

#############################
# VARIBALES
#############################

commandOutput="/tmp/hmc_$machine.$checkType.output"
commandOutputSys="/tmp/hmc_$machine.$checkType.sys"
commandOutputLpar="/tmp/hmc_$machine.$checkType.lpar"
exitCode=0
nagiosPerfdata=" |"

#############################
# MAIN
#############################

if [ -n "$machine" -a -n "$user" -a -n "$password" ]; then

        case $checkType in
                ITEMSTATUS)
			counterDown=0
			echo -ne "Infrastructure status through HMC\n\n"
			mycommand="lssyscfg -r sys -F name,type_model,serial_num,ipaddr,state"
			myresult=`echo y | /usr/bin/plink -l $user -pw $password $machine "$mycommand" > $commandOutput`
			if [ -s $commandOutput ]; then
				systemsList=""
				echo -ne "Systems List\n"
				while read line
				do
					IFS=',' read -a variablesArray <<< "${line}"
					if [ "${variablesArray[4]}" != "Operating" ]; then
						filterObj ${variablesArray[0]}
						codeFilter=$?
						if [ "$codeFilter" = "1" ]; then
							echo -ne "[FILTERED]"
						else
							echo -ne "[CRITICAL]"
							counterDown=$(( $counterDown + 1 ))
							exitCode=2
						fi
					fi
					echo -ne " ${variablesArray[0]} is ${variablesArray[4]} - IP ${variablesArray[3]} [Type ${variablesArray[1]} - S/N ${variablesArray[2]}]\n"
					systemsList="$systemsList ${variablesArray[0]}"
				done < $commandOutput
				echo -ne "\n"
				for varsys in $systemsList
				do
					mycommandL="lssyscfg -r lpar -m $varsys -F name,lpar_id,state,os_version,logical_serial_num,rmc_ipaddr"
					myresult=`echo y | /usr/bin/plink -l $user -pw $password $machine "$mycommandL" > $commandOutputLpar`
					if [ -s $commandOutputLpar ]; then
						echo -ne "Lpar on $varsys\n"
						while read lineL
						do
							IFS=',' read -a variablesArrayL <<< "${lineL}"
							if [ "${variablesArrayL[2]}" != "Running" ]; then
								filterObj ${variablesArrayL[0]}
								codeFilter=$?
								if [ "$codeFilter" = "1" ]; then
									echo -ne "[FILTERED]"
								else
									echo -ne "[CRITICAL]"
									counterDown=$(( $counterDown + 1 ))
									exitCode=2
								fi
							fi
							echo -ne " ${variablesArrayL[0]} is ${variablesArrayL[2]} - IP ${variablesArrayL[5]} [ID ${variablesArrayL[1]} - OS ${variablesArrayL[3]} - S/N ${variablesArrayL[4]}]\n"
						done < $commandOutputLpar
						echo -ne "\n"
					else
						echo -ne "Error: No lpar found on $varsys\n"
					fi
				done
			else
				echo -ne "Error: No systems found\n"
				exitCode=2
			fi
			nagiosPerfdata="$nagiosPerfdata counterDown=$counterDown;;1;0;"
                ;;
                DETAILS)
                        counterDown=0
                        echo -ne "Infrastructure details from HMC\n\n"
                        mycommand="lssyscfg -r sys -F name,type_model,serial_num,ipaddr,state"
                        myresult=`echo y | /usr/bin/plink -l $user -pw $password $machine "$mycommand" > $commandOutput`
                        if [ -s $commandOutput ]; then
                                systemsList=""
                                echo -ne "Systems List\n"
                                while read line
                                do
                                        IFS=',' read -a variablesArray <<< "${line}"
                                        if [ "${variablesArray[4]}" != "Running" ]; then
                                                counterDown=$(( $counterDown + 1 ))
                                        fi
                                        echo -ne " ${variablesArray[0]} is ${variablesArray[4]} - IP ${variablesArray[3]} [Type ${variablesArray[1]} - S/N ${variablesArray[2]}]\n"
                                        systemsList="$systemsList ${variablesArray[0]}"
                                done < $commandOutput
                                echo -ne "\n"
                                for varsys in $systemsList
                                do
                                        mycommandL="lssyscfg -r lpar -m $varsys -F name,lpar_id,state,os_version,logical_serial_num,rmc_ipaddr"
                                        myresult=`echo y | /usr/bin/plink -l $user -pw $password $machine "$mycommandL" > $commandOutputLpar`
                                        if [ -s $commandOutputLpar ]; then
                                                echo -ne "Lpar on $varsys\n"
                                                while read lineL
                                                do
                                                        IFS=',' read -a variablesArrayL <<< "${lineL}"
                                                        if [ "${variablesArrayL[2]}" != "Running" ]; then
                                                                counterDown=$(( $counterDown + 1 ))
                                                        fi
                                                        echo -ne " ${variablesArrayL[0]} is ${variablesArrayL[2]} - IP ${variablesArrayL[5]} [ID ${variablesArrayL[1]} - OS ${variablesArrayL[3]} - S/N ${variablesArrayL[4]}]\n"
                                                done < $commandOutputLpar
                                                echo -ne "\n"
                                        else
                                                echo -ne "Error: No lpar found on $varsys\n"
                                        fi
                                done
                        else
                                echo -ne "Error: No systems found\n"
                                exitCode=2
                        fi
                        nagiosPerfdata="$nagiosPerfdata counterDown=$counterDown;;1;0;"
                ;;
                LEDSTATUS)
			counterDown=0
                        echo -ne "Show Led status\n\n"
                        mycommand="lssyscfg -r sys -F name,state"
                        myresult=`echo y | /usr/bin/plink -l $user -pw $password $machine "$mycommand" > $commandOutput`
                        if [ -s $commandOutput ]; then
                                systemsList=""
                                while read line
                                do
					echo -ne "----------------------------------------\n"
                                        IFS=',' read -a variablesArray <<< "${line}"
                                        echo -ne "${variablesArray[0]} is ${variablesArray[1]}\n"
					if [ "${variablesArray[1]}" != "Operating" ]; then 
						exitCode=2 
						counterDown=$(( $counterDown + 1 ))
					fi
					mycommandL="lsled -r sa -m ${variablesArray[0]} -t"
					myresult=`echo y | /usr/bin/plink -l $user -pw $password $machine "$mycommandL phys" > $commandOutputSys`
					myresult=`echo y | /usr/bin/plink -l $user -pw $password $machine "$mycommandL virtualsys" >> $commandOutputSys`
					myresult=`echo y | /usr/bin/plink -l $user -pw $password $machine "$mycommandL virtuallpar" >> $commandOutputSys`
					myresult=`grep -v 'state=off' $commandOutputSys`
					if [ -n "$myresult" ]; then 
						exitCode=2 
						counterDown=$(( $counterDown + 1 ))
					fi
					cat $commandOutputSys
                                done < $commandOutput
                                echo -ne "\n"
                        else
                                echo -ne "Error: No systems found\n"
				exitCode=2
                        fi
			nagiosPerfdata="$nagiosPerfdata counterDown=$counterDown;;1;0;"
                ;;
                UPTIMESYS)
                        criticaluptime=1800
                        echo -ne "UpTime Systems \n"

                        mycommand="lssyscfg -r sys -F name,sys_time"
                        myresult=`echo y | /usr/bin/plink -l $user -pw $password $machine "$mycommand" > $commandOutput`
                        if [ -s $commandOutput ]; then
                                while read line
                                do
                                        IFS=',' read -a variablesArray <<< "${line}"
					uptimeSysSec=`date +%s -d "${variablesArray[1]}"`
                                        if (( $uptimeSysSec > $criticaluptime )); then
						echo -ne "OK - "
                                                exitCode=0
					else
						echo -ne "CRITICAL - "
                                                exitCode=2
                                        fi
                                        echo -ne "${variablesArray[0]} is up from ${variablesArray[1]}\n"
					nagiosPerfdata="$nagiosPerfdata uptime_${variablesArray[0]}=$uptimeSysSec;;$criticaluptime;;"
                                done < $commandOutput
                                echo -ne "\n"
                        else
                                echo -ne "Error: No systems found\n"
                                exitCode=2
                        fi
                ;;
                UPTIMEHMC)
			criticaluptime=1800
                        echo -ne "UpTime HMC "
                        mycommand="cat /proc/uptime"
                        uptimehmc=`echo y | /usr/bin/plink -l $user -pw $password $machine "$mycommand" | cut -f 1 -d .`
			
	                if (( $uptimehmc > $criticaluptime )); then
	                        echo -ne "is Ok \nSystem is UP from $uptimehmc. Alert if is down of $criticaluptime seconds. \n"
	                        exitCode=0
	                else
	                        echo -ne "is CRITICAL \nSystem is UP from $uptimehmc. Alert if is down of $criticaluptime seconds. \n"
	                        exitCode=2
	                fi
			nagiosPerfdata="$nagiosPerfdata uptime=$uptimehmc;;$criticaluptime;;"
                ;;
                DISKHMC)
                        criticalUsage=80
                        echo -ne "Disk Usage \n"
			exitCode=0

                        mycommand="monhmc -r disk -n 0"
                        myresult=`echo y | /usr/bin/plink -l $user -pw $password $machine "$mycommand" > $commandOutput`
                        if [ -s $commandOutput ]; then
				sed 1d $commandOutput > $commandOutputSys
                                while read line
                                do
                                        IFS=' ' read -a variablesArray <<< "${line}"
					usage=`echo ${variablesArray[4]} | cut -f 1 -d %`
                                        if (( $usage < $criticalUsage )); then
                                                echo -ne "OK - "
                                        else
                                                echo -ne "CRITICAL - "
                                                exitCode=2
                                        fi
					nagiosPerfdata="$nagiosPerfdata ${variablesArray[5]}=$usage;;$criticalUsage;0;100"
                                        echo -ne "${variablesArray[4]} used on ${variablesArray[5]} [FS ${variablesArray[0]} - Available ${variablesArray[3]} on ${variablesArray[1]}]\n"
                                done < $commandOutputSys
                                echo -ne "\n"
                        else
                                echo -ne "Error: No disks found\n"
                                exitCode=2
                        fi
                ;;
                HWEVENTS)
                        counter=0
                        echo -ne "Hardware Events \n\n"

                        mycommand="lssvcevents -t hardware --filter status=open"
                        myresult=`echo y | /usr/bin/plink -l $user -pw $password $machine "$mycommand" > $commandOutput`
                        if [ -s $commandOutput ]; then
                                while read line
                                do
					if [ "${line}" = "No results were found." ]; then
						echo -ne "No hardware event founds\n"
						exitCode=0
					else
	                                        IFS=',' read -a variablesArray <<< "${line}"
						counter=${#variablesArray[@]}
						#for varErr in ${#variablesArray[@]}
						for i in $(seq 0 $counter);
						do
							echo -ne "${variablesArray[$i]}\n"
						done
						echo -ne "\n"
						exitCode=2
					fi
                                done < $commandOutput
                        else
                                echo -ne "Error with log access\n"
                                exitCode=2
                        fi
			nagiosPerfdata="$nagiosPerfdata counter=$counter;;;0;"
                ;;
                CPULPAR)
			if [ -z $myAttribute ]; then
				echo -ne "Miss the System Name\n"
				exitCode=2
			else
	                        echo -ne "Cpu utilization for all Lpar on $myAttribute \n"

                                mycommandL="lssyscfg -r lpar -m $myAttribute -F name,lpar_id"
                                myresult=`echo y | /usr/bin/plink -l $user -pw $password $machine "$mycommandL" > $commandOutputLpar`
                                if [ -s $commandOutputLpar ]; then
                                        while read lineL
                                        do
                                                IFS=',' read -a variablesArrayL <<< "${lineL}"
						lpar_name="${variablesArrayL[0]}"
						lpar_id="${variablesArrayL[1]}"

			                        mycommandT="lshwres -r proc -m $myAttribute --level lpar -F curr_proc_mode,curr_proc_units --filter lpar_ids=$lpar_id"
			                        tmp_output=`echo y | /usr/bin/plink -l $user -pw $password $machine "$mycommandT"`
						IFS=',' read -a tmpArray <<< "$tmp_output"
				                curr_proc_mode="${tmpArray[0]}"
				                curr_proc_units="${tmpArray[1]}"

			                        mycommand="lslparutil -m $myAttribute -r lpar -F time,lpar_id,capped_cycles,uncapped_cycles,entitled_cycles,idle_cycles,time_cycles --filter lpar_names=$lpar_name -n 11"
			                        myresult=`echo y | /usr/bin/plink -l $user -pw $password $machine "$mycommand" > $commandOutput`
			                        if [ -s $commandOutput ]; then
							firstLine=`sed -n '1p' $commandOutput`
							secondLine=`sed -n '11p' $commandOutput`
							IFS=',' read -a firstArray <<< "$firstLine"
				                        f_time="${firstArray[0]}"
				                        f_lpar_id="${firstArray[1]}"
				                        f_capped_cycles="${firstArray[2]}"
				                        f_uncapped_cycles="${firstArray[3]}"
				                        f_entitled_cycles="${firstArray[4]}"
				                        f_idle_cycles="${firstArray[5]}"
				                        f_time_cycles="${firstArray[6]}"
	
							IFS=',' read -a secondArray <<< "$secondLine"
				                        s_time="${secondArray[0]}"
				                        s_lpar_id="${secondArray[1]}"
				                        s_capped_cycles="${secondArray[2]}"
				                        s_uncapped_cycles="${secondArray[3]}"
				                        s_entitled_cycles="${secondArray[4]}"
				                        s_idle_cycles="${secondArray[5]}"
				                        s_time_cycles="${secondArray[6]}"
				
							sharedProc="((($f_capped_cycles - $s_capped_cycles) + ($f_uncapped_cycles - $s_uncapped_cycles)) / ($f_entitled_cycles - $s_entitled_cycles)) * 100"
							sharedProcUnit="(($f_capped_cycles - $s_capped_cycles) + ($f_uncapped_cycles - $s_uncapped_cycles)) / ($f_time_cycles - $s_time_cycles)"
							#dedicatedProc="((($f_capped_cycles - $s_capped_cycles) - ($f_idle_cycles - $s_idle_cycles)) / ($f_capped_cycles - $s_capped_cycles)) * 100"
							#dedicatedProcUnit="(($f_pped_cycles - $s_capped_cycles) - ($f_idle_cycles - $s_idle_cycles)) / ($f_time_cycles - $s_time_cycles)"
	
							sharedProc=`echo "$sharedProc" | bc -l`
							sharedProcUnit=`echo "$sharedProcUnit" | bc -l`
							#dedicatedProc=`echo "$dedicatedProc" | bc -l`
							#dedicatedProcUnit=`echo "$dedicatedProcUnit" | bc -l`
							tmpK=`expr match $sharedProcUnit .`
							if [ "$tmpK" = "1" ]; then
								sharedProcUnit="0$sharedProcUnit"
							fi
							tmpK=`expr match $sharedProc .`
							if [ "$tmpK" = "1" ]; then
								sharedProc="0$sharedProc"
							fi
							sharedProcUnit=$( echo $sharedProcUnit | awk '{printf("%.5f\n", $1)}' )
							sharedProc=$( echo $sharedProc | awk '{printf("%.5f\n", $1)}' )
	
							echo -ne "CPU on $lpar_name [Updated: $f_time]\n"
							echo -ne "Entitled processor cores $curr_proc_units - Mode: $curr_proc_mode\n"
							echo -ne "Share Processor Unit Utilized = $sharedProcUnit\n"
							echo -ne "Share Processor Utilization % = $sharedProc\n\n"
							#echo -ne "Dedicated Processor Unit Utilized = $dedicatedProcUnit\n"
							#echo -ne "Dedicated Processor Utilization % = $dedicatedProc\n\n"
				
							nagiosPerfdata="$nagiosPerfdata CPU_%_$lpar_name=$sharedProc;;;0;100 CPU_$lpar_name=$sharedProcUnit;;;0;$curr_proc_units"

		        	                else
			                                echo -ne "Error with access\n"
			                                exitCode=2
			                        fi

                                        done < $commandOutputLpar
                                else
                                        echo -ne "Error: No lpar found on $myAttribute\n"
                                fi

			fi 

		;;

                *)
                        echo -ne "SCRIPT ERROR: Change Check Type. \n"
                        exitCode=3
                ;;

	esac
        
else

        echo -ne "SCRIPT ERROR: Check your options. There is an error or missing same informations. \n"
        exitCode=3

fi

#################################
# Print performance
#################################

echo -ne "$nagiosPerfdata \n"

#################################
# delete the tmp file
#################################

rm -rf $commandOutput
rm -rf $commandOutputSys
rm -rf $commandOutputLpar

exit $exitCode

