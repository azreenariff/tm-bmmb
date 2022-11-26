#!/bin/ksh
#
# $Id: check_hmc.sh 345 2013-12-03 19:07:10Z u09422fra $
#
# HMC/pSeries health monitoring plugin for Nagios 
#
# Paths 
AWK="/usr/bin/awk"
BC="/usr/bin/bc"
CAT="/bin/cat"
CUT="/usr/bin/cut"
EGREP="/bin/egrep"
MKTEMP="/usr/bin/mktemp"
RM="/bin/rm"
SSH="/usr/bin/ssh"
SED="/bin/sed"
WC="/usr/bin/wc"

# Nagios return codes and strings
R_OK=0;       S_OK="OK"
R_WARNING=1;  S_WARNING="WARNING"
R_CRITICAL=2; S_CRITICAL="CRITICAL"
R_UNKNOWN=3;  S_UNKNOWN="UNKNOWN"
R_ALL=0;      S_ALL=""

# Variables
SSHKEY="/home/nagios/.ssh/id_rsa"
SSHARG="-i ${SSHKEY} -l hscroot"
PROGNAME=$(basename $0)
CHECK=""                # Which check to run
CHECK_ARG=""            # Argument for check
CRITICAL=""             # Critical threshold
WARNING=""              # Warning threshold
HMC=""                  # HMC to check
MONHMC="monhmc -n 0"    # HMC monhmc command line
RC=0

# The following HMC events can savely be ignored. String is a egrep regex.
# B3010002, 2535902, 25C3902 - HMC or partition connection monitoring fault
EVENT_FILTER="B3010002|2535902|25C3902"

if [ ! -x ${SSH} ]; then
    echo "UNKNOWN: ${SSH} not found or not executable."
    exit ${R_UNKNOWN}
fi
if [ ! -f ${SSHKEY} ]; then
    echo "UNKNOWN: ${SSHKEY} not found."
    exit ${R_UNKNOWN}
fi

# Functions
# Display usage
usage () {
    echo "Usage: ${PROGNAME} [-h] -H <hmc> -C <check> -w <warn> -c <crit>"
    echo "    -h display help"
    echo "    -H run check on this HMC"
    echo "    -C run one of the following checks:"
    echo "        disk, events, ledphys, ledvlpar, ledvsys, mem, proc, rmc, swap"
    echo "    -a run check with argument:"
    echo "        filesystem for disk check"
    echo "        process name for rmc check"
    echo "    -w Warning threshold"
    echo "    -c Critical threshold"
    echo ""
    exit ${R_UNKNOWN}
}

# Get command line options
[ $# -eq 0 ] && usage
while getopts  "ha:c:w:C:H:" OPTION; do
    case ${OPTION} in
        h) usage ;;
        a) if [[ ! -z ${OPTARG} ]]; then
               CHECK_ARG=${OPTARG}
           else
               usage
           fi
        ;;
        c) if [[ ${OPTARG} = +([0-9.])*(%) ]]; then
               CRITICAL=${OPTARG}
           else
               usage
           fi
        ;;
        w) if [[ ${OPTARG} = +([0-9.])*(%) ]]; then
               WARNING=${OPTARG}
           else
               usage
           fi
        ;;
        C) if [[ ! -z ${OPTARG} ]]; then
               CHECK=${OPTARG}
           else
               usage
           fi
        ;;
        H) if [[ ! -z ${OPTARG} ]]; then
               HMC=${OPTARG}
           else
               usage
           fi
        ;;
        *) usage ;;
    esac
done
[[ -z ${CHECK} || -z ${HMC} ]] && usage
[[ ( ${CHECK} != "ledphys" && ${CHECK} != "ledvsys" && ${CHECK} != "ledvlpar" && ${CHECK} != "events" ) && ( -z ${CRITICAL} || -z ${WARNING} ) ]] && usage

if [[ ${CHECK} == "disk" || ${CHECK} == "rmc" ]]; then
    [[ -z ${CHECK_ARG} ]] && usage
fi

TMPFILE="`${MKTEMP} /tmp/${PROGNAME}.${HMC}.${CHECK}.XXXXXXXX`"
RC=$?
if [[ ${RC} -ne 0 ]]; then
    echo "UNKNOWN: Cannot create tempfile."
    exit ${R_UNKNOWN}
fi

case ${CHECK} in
    disk)
        ${SSH} ${SSHARG} ${HMC} "${MONHMC} -r ${CHECK}" > ${TMPFILE}
        FS_MATCH="`${EGREP} "${CHECK_ARG}" ${TMPFILE} | ${WC} -l`"
        if [[ ${FS_MATCH} -ne 1 ]]; then
            echo "UNKNOWN: Expression \"${CHECK_ARG}\" matches more than one filesystem."
            [[ -e ${TMPFILE} ]] && ${RM} -f ${TMPFILE}
            exit ${R_UNKNOWN}
        fi
        FS_LINE="`${EGREP} "${CHECK_ARG}" ${TMPFILE}`"
        RC=$?
        [[ -e ${TMPFILE} ]] && ${RM} -f ${TMPFILE}
        if [[ ${RC} -ne 0 ]]; then
            echo "UNKNOWN: Filesystem \"${CHECK_ARG}\" not found."
            exit ${R_UNKNOWN}
        fi

        FS_FREE_MB="`echo ${FS_LINE} | ${CUT} -d ' ' -f 4`"
        FS_FREE_MB="$((FS_FREE_MB/1024))"
        FS_USE_PCT="`echo ${FS_LINE} | ${CUT} -d ' ' -f 5`"
        FS_USE_PCT="${FS_USE_PCT%\%}"
        FS_FREE_PCT="$((100-FS_USE_PCT))"
        FS_NAME="`echo ${FS_LINE} | ${CUT} -d ' ' -f 6`"

        UNIT="${CRITICAL##+([0-9])}"
        if [[ "${UNIT}" == "%" ]]; then
            CRITICAL="${CRITICAL%\%}"
            if [[ ${FS_FREE_PCT} -lt ${CRITICAL} ]]; then
                echo "DISK ${S_CRITICAL} - free space: ${FS_NAME} ${FS_FREE_MB} MB (${FS_FREE_PCT}%) | ${FS_NAME}=${FS_FREE_PCT}%;${WARNING%\%};${CRITICAL%\%};0;100"
                exit ${R_CRITICAL}
            fi 
        else
            if [[ ${FS_FREE_MB} -lt ${CRITICAL} ]]; then
                echo "DISK ${S_CRITICAL} - free space: ${FS_NAME} ${FS_FREE_MB} MB (${FS_FREE_PCT}%) | ${FS_NAME}=${FS_FREE_MB}MB;${WARNING};${CRITICAL};;"
                exit ${R_CRITICAL}
            fi 
        fi
        UNIT="${WARNING##+([0-9])}"
        if [[ "${UNIT}" == "%" ]]; then
            WARNING="${WARNING%\%}"
            if [[ ${FS_FREE_PCT} -lt ${WARNING} ]]; then
                echo "DISK ${S_WARNING} - free space: ${FS_NAME} ${FS_FREE_MB} MB (${FS_FREE_PCT}%) | ${FS_NAME}=${FS_FREE_PCT}%;${WARNING%\%};${CRITICAL%\%};0;100"
                exit ${R_WARNING}
            fi 
        else
            if [[ ${FS_FREE_MB} -lt ${WARNING} ]]; then
                echo "DISK ${S_WARNING} - free space: ${FS_NAME} ${FS_FREE_MB} MB (${FS_FREE_PCT}%) | ${FS_NAME}=${FS_FREE_MB}MB;${WARNING};${CRITICAL};;"
                exit ${R_WARNING}
            fi 
        fi

        if [[ "${UNIT}" == "%" ]]; then
            echo "DISK ${S_OK} - free space: ${FS_NAME} ${FS_FREE_MB} MB (${FS_FREE_PCT}%) | ${FS_NAME}=${FS_FREE_PCT}%;${WARNING%\%};${CRITICAL%\%};0;100"
        else
            echo "DISK ${S_OK} - free space: ${FS_NAME} ${FS_FREE_MB} MB (${FS_FREE_PCT}%) | ${FS_NAME}=${FS_FREE_MB}MB;${WARNING};${CRITICAL};;"
        fi
        exit ${R_OK}
    ;;
    events)
        ${SSH} ${SSHARG} ${HMC} 'lssvcevents -t hardware -i 1440 --filter "status=open"' | \
            ${EGREP} -v "${EVENT_FILTER}" > ${TMPFILE}
        C_MSYS="`${WC} -l ${TMPFILE} | ${CUT} -d ' ' -f 1`"
        if [[ ${C_MSYS} -lt 1 ]]; then
            echo "UNKNOWN: Eventlog on HMC has no enties."
            [[ -e ${TMPFILE} ]] && ${RM} -f ${TMPFILE}
            exit ${R_UNKNOWN}
        fi

        ${EGREP} -q "^No results were found.$" ${TMPFILE}
        RC=$?

        if [[ ${RC} -eq 0 ]]; then
            R_ALL=${R_OK}
        else
            while read line; do
                if [[ ${line} = problem_num* ]]; then
                    PNUM="`echo ${line} | ${CUT} -d , -f 1`";  PNUM="${PNUM##*=}"
                    PREF="`echo ${line} | ${CUT} -d , -f 3`";  PREF="${PREF##*=}"
                    #PTIME="`echo ${line} | ${CUT} -d , -f 5`"; PTIME="${PTIME##*=}"
                    PMSYS="`echo ${line} | ${CUT} -d , -f 7`"; PMSYS="${PMSYS##*=}"
                    S_ALL="${S_ALL} ${PNUM}:${PMSYS}:${PREF};"
                    R_ALL=${R_CRITICAL}
                fi
            done < ${TMPFILE}
        fi
        [[ -e ${TMPFILE} ]] && ${RM} -f ${TMPFILE}
        
        if [[ ${R_ALL} -eq ${R_CRITICAL} ]]; then
            S_ALL="EVENTS ${S_CRITICAL} -${S_ALL}"
        elif [[ ${R_ALL} -eq ${R_OK} ]]; then
            S_ALL="EVENTS ${S_OK} - No serviceable events found."
        fi
        echo ${S_ALL}
        exit ${R_ALL}
    ;;
    ledphys)
        ${SSH} ${SSHARG} ${HMC} 'for MSYS in `lssyscfg -r sys -F name `; do echo -n "${MSYS} "; lsled -r sa -t phys -m ${MSYS}; done' > ${TMPFILE}
        C_MSYS="`${WC} -l ${TMPFILE} | ${CUT} -d ' ' -f 1`"
        if [[ ${C_MSYS} -le 0 ]]; then
            echo "UNKNOWN: No managed system found on HMC."
            [[ -e ${TMPFILE} ]] && ${RM} -f ${TMPFILE}
            exit ${R_UNKNOWN}
        fi

        while read MSYS STATE line; do
            STATE="${STATE##*=}"
            if [[ -z ${STATE} ]]; then
                echo "UNKNOWN: Invalid value \"${STATE}\" for managed system."
                [[ -e ${TMPFILE} ]] && ${RM} -f ${TMPFILE}
                exit ${R_UNKNOWN}
            fi
           
            S_ALL="${S_ALL} ${MSYS} LED \"${STATE}\""
            if [[ ${STATE} != "off" ]]; then
                R_ALL=${R_CRITICAL}
            fi 
        done < ${TMPFILE}
        [[ -e ${TMPFILE} ]] && ${RM} -f ${TMPFILE}
        
        if [[ ${R_ALL} -eq ${R_CRITICAL} ]]; then
            S_ALL="LED ${S_CRITICAL} -${S_ALL}"
        elif [[ ${R_ALL} -eq ${R_OK} ]]; then
            S_ALL="LED ${S_OK} - All LEDs \"off\"."
        fi
        echo ${S_ALL}
        exit ${R_ALL}
    ;;
    ledvlpar)
        ${SSH} ${SSHARG} ${HMC} 'for MSYS in `lssyscfg -r sys -F name `; do echo "BEGIN:${MSYS} "; lsled -r sa -t virtuallpar -m ${MSYS}; echo "END:${MSYS} "; done' > ${TMPFILE}
        C_MSYS="`${WC} -l ${TMPFILE} | ${CUT} -d ' ' -f 1`"
        if [[ ${C_MSYS} -le 0 ]]; then
            echo "UNKNOWN: No managed system found on HMC."
            [[ -e ${TMPFILE} ]] && ${RM} -f ${TMPFILE}
            exit ${R_UNKNOWN}
        fi

        while read line; do
            if [[ ${line} = BEGIN:* ]]; then
                if [[ -z ${MSYSB} ]]; then
                    MSYSB="${line##*:}"
                else
                    echo "UNKNOWN: No \"END:\" tag found for managed system ${MSYSB}."
                    [[ -e ${TMPFILE} ]] && ${RM} -f ${TMPFILE}
                    exit ${R_UNKNOWN}
                fi
            elif [[ ${line} = END:* ]]; then
                if [[ -z ${MSYSE} || "${MSYSE}" != "${MSYSB}" ]]; then
                    MSYSE="${line##*:}"
                    MSYSB=""
                else
                    echo "UNKNOWN: No \"BEGIN:\" tag found for managed system ${MSYSE}."
                    [[ -e ${TMPFILE} ]] && ${RM} -f ${TMPFILE}
                    exit ${R_UNKNOWN}
                fi
            elif [[ ${line} = lpar_id* ]]; then
                line="`echo $line | ${SED} -e 's/ \r$//'`"
                LPARID="`echo ${line} | ${CUT} -d , -f 1`";   LPARID="${LPARID##*=}"
                LPARNAME="`echo ${line} | ${CUT} -d , -f 2`"; LPARNAME="${LPARNAME##*=}"
                STATE="`echo ${line} | ${CUT} -d , -f 3`";    STATE="${STATE##*=}"
                if [[ ${STATE} != "off" ]]; then
                    S_ALL="${S_ALL} ${MSYSB}:${LPARID} (${LPARNAME}) LED \"${STATE}\";"
                    R_ALL=${R_CRITICAL}
                fi 
            else
                echo "UNKNOWN: Unknown output \"${line}\"."
                [[ -e ${TMPFILE} ]] && ${RM} -f ${TMPFILE}
                exit ${R_UNKNOWN}
            fi
        done < ${TMPFILE}
        [[ -e ${TMPFILE} ]] && ${RM} -f ${TMPFILE}
        
        if [[ ${R_ALL} -eq ${R_CRITICAL} ]]; then
            S_ALL="LED ${S_CRITICAL} -${S_ALL}"
        elif [[ ${R_ALL} -eq ${R_OK} ]]; then
            S_ALL="LED ${S_OK} - All LED \"off\"."
        fi
        echo ${S_ALL}
        exit ${R_ALL}
    ;;
    ledvsys)
        ${SSH} ${SSHARG} ${HMC} 'for MSYS in `lssyscfg -r sys -F name `; do echo -n "${MSYS} "; lsled -r sa -t virtualsys -m ${MSYS}; done' > ${TMPFILE}
        C_MSYS="`${WC} -l ${TMPFILE} | ${CUT} -d ' ' -f 1`"
        if [[ ${C_MSYS} -le 0 ]]; then
            echo "UNKNOWN: No managed system found on HMC."
            [[ -e ${TMPFILE} ]] && ${RM} -f ${TMPFILE}
            exit ${R_UNKNOWN}
        fi

        while read MSYS STATE line; do
            STATE="${STATE##*=}"
            if [[ -z ${STATE} ]]; then
                echo "UNKNOWN: Invalid value \"${STATE}\" for managed system."
                [[ -e ${TMPFILE} ]] && ${RM} -f ${TMPFILE}
                exit ${R_UNKNOWN}
            fi
           
            if [[ ${STATE} != "off" ]]; then
                S_ALL="${S_ALL} ${MSYS} LED \"${STATE}\""
                R_ALL=${R_CRITICAL}
            fi 
        done < ${TMPFILE}
        [[ -e ${TMPFILE} ]] && ${RM} -f ${TMPFILE}
        
        if [[ ${R_ALL} -eq ${R_CRITICAL} ]]; then
            S_ALL="LED ${S_CRITICAL} -${S_ALL}"
        elif [[ ${R_ALL} -eq ${R_OK} ]]; then
            S_ALL="LED ${S_OK} - All LED \"off\"."
        fi
        echo ${S_ALL}
        exit ${R_ALL}
    ;;
    mem)
        ${SSH} ${SSHARG} ${HMC} "${MONHMC} -r ${CHECK}" > ${TMPFILE}
        MEM_MATCH="`${WC} -l ${TMPFILE} | ${CUT} -d ' ' -f 1`"
        if [[ ${MEM_MATCH} -ne 1 ]]; then
            echo "UNKNOWN: \"${TMPFILE}\" contains unknown data."
            [[ -e ${TMPFILE} ]] && ${RM} -f ${TMPFILE}
            exit ${R_UNKNOWN}
        fi

        #read dummy1 MEM_TOTAL dummy2 MEM_USED dummy3 MEM_FREE line < ${TMPFILE}
        read MEM_MSR dummy2 dummy3 MEM_TOTAL dummy2 MEM_FREE dummy3 MEM_USED line < ${TMPFILE}
        [[ -e ${TMPFILE} ]] && ${RM} -f ${TMPFILE}
        if [[ "${MEM_MSR}" == "KiB" ]]; then
            MEM_TOTAL="${MEM_TOTAL%k}"; MEM_TOTAL="$((MEM_TOTAL/1024))"
        elif [[ "${MEM_TOTAL}" == *"M" ]]; then
            MEM_TOTAL="${MEM_TOTAL%M}"; MEM_TOTAL="$((MEM_TOTAL))"
        else
            echo "UNKNOWN: MEM_TOTAL unit of measurement unknown."
            exit ${R_UNKNOWN}
        fi
        if [[ "${MEM_MSR}" == "KiB" ]]; then
            MEM_USED="${MEM_USED%k}";   MEM_USED="$((MEM_USED/1024))"
        elif [[ "${MEM_USED}" == *"M" ]]; then
            MEM_USED="${MEM_USED%M}";   MEM_USED="$((MEM_USED))"
        else
            echo "UNKNOWN: MEM_USED unit of measurement unknown."
            exit ${R_UNKNOWN}
        fi
        if [[ "${MEM_MSR}" == "KiB" ]]; then
            MEM_FREE="${MEM_FREE%k}";   MEM_FREE="$((MEM_FREE/1024))"
        elif [[ "${MEM_FREE}" == *"M" ]]; then
            MEM_FREE="${MEM_FREE%M}";   MEM_FREE="$((MEM_FREE))"
        else
            echo "UNKNOWN: MEM_FREE unit of measurement unknown."
            exit ${R_UNKNOWN}
        fi
        if [[ -z ${MEM_TOTAL} || -z ${MEM_USED} || -z ${MEM_FREE} ]]; then
            echo "UNKNOWN: MEM_TOTAL, MEM_USED or MEM_FREE have invalid values."
            exit ${R_UNKNOWN}
        fi
       
        if [[ ${MEM_FREE} -lt ${CRITICAL} ]]; then
            echo "MEM ${S_CRITICAL} - free memory: ${MEM_FREE} MB, used memory: ${MEM_USED} MB, total memory: ${MEM_TOTAL} MB | free=${MEM_FREE}MB;${WARNING};${CRITICAL};0;${MEM_TOTAL}"
            exit ${R_CRITICAL}
        elif [[ ${MEM_FREE} -lt ${WARNING} ]]; then
            echo "MEM ${S_WARNING} - free memory: ${MEM_FREE} MB, used memory: ${MEM_USED} MB, total memory: ${MEM_TOTAL} MB | free=${MEM_FREE}MB;${WARNING};${CRITICAL};0;${MEM_TOTAL}"
            exit ${R_WARNING}
        else
            echo "MEM ${S_OK} - free memory: ${MEM_FREE} MB, used memory: ${MEM_USED} MB, total memory: ${MEM_TOTAL} MB | free=${MEM_FREE}MB;${WARNING};${CRITICAL};0;${MEM_TOTAL}"
            exit ${R_OK}
        fi 
    ;;
    proc)
        ${SSH} ${SSHARG} ${HMC} "${MONHMC} -r ${CHECK}" > ${TMPFILE}.tmp
        ${SED} -e 's/% /%/g' ${TMPFILE}.tmp > ${TMPFILE}
        [[ -e ${TMPFILE}.tmp ]] && ${RM} -f ${TMPFILE}.tmp
        CPU_MATCH="`${EGREP} "Cpu" ${TMPFILE} | ${WC} -l`"
        #if [[ ${CPU_MATCH} -ne 1 && ${CPU_MATCH} -ne 2 &&
        #      ${CPU_MATCH} -ne 3 && ${CPU_MATCH} -ne 4 &&
        #      ${CPU_MATCH} -ne 5 && ${CPU_MATCH} -ne 6 &&
        #      ${CPU_MATCH} -ne 7 && ${CPU_MATCH} -ne 8 &&
        #      ${CPU_MATCH} -ne 9 && ${CPU_MATCH} -ne 10 &&
        #      ${CPU_MATCH} -ne 11 ]]; then
        #    echo "UNKNOWN: \"${TMPFILE}\" contains unknown data."
        #    [[ -e ${TMPFILE} ]] && ${RM} -f ${TMPFILE}
        #    exit ${R_UNKNOWN}
        #fi

        S_ALL="Statistics:"
        S_PERF=""
        # us: user cpu time (or) % CPU time spent in user space
        # sy: system cpu time (or) % CPU time spent in kernel space
        # ni: user nice cpu time (or) % CPU time spent on low priority processes
        # id: idle cpu time (or) % CPU time spent idle
        # wa: io wait cpu time (or) % CPU time spent in wait (on disk)
        # hi: hardware irq (or) % CPU time spent servicing/handling hardware interrupts
        # si: software irq (or) % CPU time spent servicing/handling software interrupts
        # st: steal time - - % CPU time in involuntary wait by virtual cpu while hypervisor
        #     is servicing another processor (or) % CPU time stolen from a virtual machine
        while IFS=',' read CPU_USER CPU_SYS CPU_NICE CPU_IDLE CPU_WAIT CPU_HI CPU_SI CPU_ST line; do
            CPU="${CPU_USER%% *}"
            CPU="${CPU#Cpu}"
            CPU="${CPU:1}"
            #CPU_USER="${CPU_USER##* }"
            CPU_USER="${CPU_USER%\%us}"
            CPU_USER=$( echo ${CPU_USER} | awk '{print $3}' | awk '{printf "%0.0f\n", $1}' )
            CPU_SYS="${CPU_SYS#"${CPU_SYS%%[![:space:]]*}"}"
            #CPU_SYS="${CPU_SYS%\%sy}"
            CPU_SYS=$( echo ${CPU_SYS%\%sy} | awk '{printf "%0.0f\n", $1}' )
            CPU_NICE="${CPU_NICE#"${CPU_NICE%%[![:space:]]*}"}"
            #CPU_NICE="${CPU_NICE%\%ni}"
            CPU_NICE=$( echo ${CPU_NICE%\%ni} | awk '{printf "%0.0f\n", $1}' )
            CPU_IDLE="${CPU_IDLE#"${CPU_IDLE%%[![:space:]]*}"}"
            #CPU_IDLE="${CPU_IDLE%\%id}"
            CPU_IDLE=$( echo ${CPU_IDLE%\%id} | awk '{printf "%0.0f\n", $1}' )
            CPU_WAIT="${CPU_WAIT#"${CPU_WAIT%%[![:space:]]*}"}"
            #CPU_WAIT="${CPU_WAIT%\%wa}"
            CPU_WAIT=$( echo ${CPU_WAIT%\%wa} | awk '{printf "%0.0f\n", $1}' )
            CPU_HI="${CPU_HI#"${CPU_HI%%[![:space:]]*}"}"
            #CPU_HI="${CPU_HI%\%hi}"
            CPU_HI=$( echo ${CPU_HI%\%hi} | awk '{printf "%0.0f\n", $1}' )
            CPU_SI="${CPU_SI#"${CPU_SI%%[![:space:]]*}"}"
            #CPU_SI="${CPU_SI%\%si}"
            CPU_SI=$( echo ${CPU_SI%\%si} | awk '{printf "%0.0f\n", $1}' )
            CPU_ST="${CPU_ST#"${CPU_ST%%[![:space:]]*}"}"
            #CPU_ST="${CPU_ST%\%st}"
            CPU_ST=$( echo ${CPU_ST%\%st} | awk '{printf "%0.0f\n", $1}' )

            if [[ -z ${CPU_USER} || -z ${CPU_SYS} || -z ${CPU_NICE} || -z ${CPU_IDLE} || -z ${CPU_WAIT} ]]; then
                echo "UNKNOWN: CPU_USER, CPU_SYS, CPU_NICE, CPU_IDLE or CPU_WAIT have invalid values."
                [[ -e ${TMPFILE} ]] && ${RM} -f ${TMPFILE}
                exit ${R_UNKNOWN}
            fi

            S_GENERIC="user=${CPU_USER}% system=${CPU_SYS}% idle=${CPU_IDLE}% iowait=${CPU_WAIT}%"
            if [[ -z ${S_PERF} ]]; then
                S_PERF="${CPU}_user=${CPU_USER}%;;;0;100 ${CPU}_system=${CPU_SYS}%;;;0;100 ${CPU}_idle=${CPU_IDLE}%;${WARNING};${CRITICAL};0;100 ${CPU}_iowait=${CPU_WAIT}%;;;0;100"
            else
                S_PERF="${S_PERF} ${CPU}_user=${CPU_USER}%;;;0;100 ${CPU}_system=${CPU_SYS}%;;;0;100 ${CPU}_idle=${CPU_IDLE}%;${WARNING};${CRITICAL};0;100 ${CPU}_iowait=${CPU_WAIT}%;;;0;100"
            fi

            if [[ ! -z ${CPU_HI} ]]; then
                S_GENERIC="${S_GENERIC} hirq=${CPU_HI}%"
                S_PERF="${S_PERF} ${CPU}_hirq=${CPU_HI}%;;;0;100"
            fi
            if [[ ! -z ${CPU_SI} ]]; then
                S_GENERIC="${S_GENERIC} sirq=${CPU_SI}%"
                S_PERF="${S_PERF} ${CPU}_sirq=${CPU_SI}%;;;0;100"
            fi
            if [[ ! -z ${CPU_ST} ]]; then
                S_GENERIC="${S_GENERIC} steal=${CPU_ST}%"
                S_PERF="${S_PERF} ${CPU}_steal=${CPU_ST}%;;;0;100"
            fi
           
            S_ALL="${S_ALL} ${CPU}: ${S_GENERIC}"
            if [[ `echo "${CPU_IDLE} <= ${CRITICAL}" | ${BC} -l` -eq 1 ]]; then
                R_ALL=${R_CRITICAL}
            elif [[ `echo "${CPU_IDLE} <= ${WARNING}" | ${BC} -l` -eq 1 ]]; then
                [[ ${R_ALL} -lt ${R_WARNING} ]] && R_ALL=${R_WARNING}
            fi 
        done < ${TMPFILE}
        [[ -e ${TMPFILE} ]] && ${RM} -f ${TMPFILE}

        if [[ ${R_ALL} -eq ${R_CRITICAL} ]]; then
            S_ALL="CPU ${S_CRITICAL} - ${S_ALL}"
        elif [[ ${R_ALL} -eq ${R_WARNING} ]]; then
            S_ALL="CPU ${S_WARNING} - ${S_ALL}"
        elif [[ ${R_ALL} -eq ${R_OK} ]]; then
            S_ALL="CPU ${S_OK} - ${S_ALL}"
        fi
        echo "${S_ALL} | ${S_PERF}"
        exit ${R_ALL}
    ;;
    rmc)
        ${SSH} ${SSHARG} ${HMC} "${MONHMC} -s ${CHECK}" > ${TMPFILE}
        PROC_MATCH="`${EGREP} "${CHECK_ARG}" ${TMPFILE} | ${WC} -l`"
        [[ -e ${TMPFILE} ]] && ${RM} -f ${TMPFILE}
        if [[ ${PROC_MATCH} -lt ${CRITICAL} ]]; then
            echo "PROCS ${S_CRITICAL}: ${PROC_MATCH} process with command name '${CHECK_ARG}'"
            exit ${R_CRITICAL}
        elif [[ ${PROC_MATCH} -lt ${WARNING} ]]; then
            echo "PROCS ${S_WARNING}: ${PROC_MATCH} process with command name '${CHECK_ARG}'"
            exit ${R_WARNING}
        else
            echo "PROCS ${S_OK}: ${PROC_MATCH} process with command name '${CHECK_ARG}'"
            exit ${R_OK}
        fi
    ;;
    swap)
        ${SSH} ${SSHARG} ${HMC} "${MONHMC} -r ${CHECK}" > ${TMPFILE}
        SWAP_MATCH="`${WC} -l ${TMPFILE} | ${CUT} -d ' ' -f 1`"
        if [[ ${SWAP_MATCH} -ne 1 ]]; then
            echo "UNKNOWN: \"${TMPFILE}\" contains unknown data."
            [[ -e ${TMPFILE} ]] && ${RM} -f ${TMPFILE}
            exit ${R_UNKNOWN}
        fi

        #read dummy1 SWAP_TOTAL dummy2 SWAP_USED dummy3 SWAP_FREE line < ${TMPFILE}
        read SWAP_MSR dummy2 SWAP_TOTAL dummy3 SWAP_FREE dummy4 SWAP_USED line < ${TMPFILE}
        [[ -e ${TMPFILE} ]] && ${RM} -f ${TMPFILE}
        if [[ "${SWAP_MSR}" == "KiB" ]]; then
            SWAP_TOTAL="${SWAP_TOTAL%k}"; SWAP_TOTAL="$((SWAP_TOTAL/1024))"
        elif [[ "${SWAP_TOTAL}" == *"M" ]]; then
            SWAP_TOTAL="${SWAP_TOTAL%M}"; SWAP_TOTAL="$((SWAP_TOTAL))"
        else
            echo "UNKNOWN: SWAP_TOTAL unit of measurement unknown."
            exit ${R_UNKNOWN}
        fi
        if [[ "${SWAP_MSR}" == "KiB" ]]; then
            SWAP_USED="${SWAP_USED%k}";   SWAP_USED="$((SWAP_USED/1024))"
        elif [[ "${SWAP_USED}" == *"M" ]]; then
            SWAP_USED="${SWAP_USED%M}";   SWAP_USED="$((SWAP_USED))"
        else
            echo "UNKNOWN: SWAP_USED unit of measurement unknown."
            exit ${R_UNKNOWN}
        fi
        if [[ "${SWAP_MSR}" == "KiB" ]]; then
            SWAP_FREE="${SWAP_FREE%k}";   SWAP_FREE="$((SWAP_FREE/1024))"
        elif [[ "${SWAP_FREE}" == *"M" ]]; then
            SWAP_FREE="${SWAP_FREE%M}";   SWAP_FREE="$((SWAP_FREE))"
        else
            echo "UNKNOWN: SWAP_FREE unit of measurement unknown."
            exit ${R_UNKNOWN}
        fi
        if [[ -z ${SWAP_TOTAL} || -z ${SWAP_USED} || -z ${SWAP_FREE} ]]; then
            echo "UNKNOWN: SWAP_TOTAL, SWAP_USED or SWAP_FREE have invalid values."
            exit ${R_UNKNOWN}
        fi

        if [[ ${SWAP_FREE} -lt ${CRITICAL} ]]; then
            echo "SWAP ${S_CRITICAL} - free swap: ${SWAP_FREE} MB, used swap: ${SWAP_USED} MB, total swap: ${SWAP_TOTAL} MB | free=${SWAP_FREE}MB;${WARNING};${CRITICAL};0;${SWAP_TOTAL}"
            exit ${R_CRITICAL}
        elif [[ ${SWAP_FREE} -lt ${WARNING} ]]; then
            echo "SWAP ${S_WARNING} - free swap: ${SWAP_FREE} MB, used swap: ${SWAP_USED} MB, total swap: ${SWAP_TOTAL} MB | free=${SWAP_FREE}MB;${WARNING};${CRITICAL};0;${SWAP_TOTAL}"
            exit ${R_WARNING}
        else
            echo "SWAP ${S_OK} - free swap: ${SWAP_FREE} MB, used swap: ${SWAP_USED} MB, total swap: ${SWAP_TOTAL} MB | free=${SWAP_FREE}MB;${WARNING};${CRITICAL};0;${SWAP_TOTAL}"
            exit ${R_OK}
        fi 
    ;;
    *) usage ;;
esac

[[ -e ${TMPFILE} ]] && ${RM} -f ${TMPFILE}

exit 0
#
## EOF
