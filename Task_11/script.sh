#!/bin/bash
PIDs=`ls /proc | grep -E "^[0-9]+$"`
CLK_TCK=`getconf CLK_TCK`

RESULT_DISPLAY="PID\tTTY\tSTAT\tTIME\tCMD\n"
for PID in $PIDs
do 
	if [ -e /proc/$PID/fd/0 ]
	then
		 tty=`ls -l /proc/$PID/fd/0 | awk -F '> /dev/' '{print $2}'`
	else
		tty="none"
	fi
	if [ -e /proc/$PID/stat ]
	then
		stat=(`cat /proc/$PID/stat`)
	else
		continue
	fi
	cmd=`cat /proc/$PID/cmdline | tr -d "\0"`
	if [ -z "$cmd" ]
	then
		cmd=${stat[1]}
	fi
	pid_stat=${stat[2]}
	
	let "u_cpu=((${stat[13]}+${stat[14]})/$CLK_TCK)"
	mm=$((( u_cpu/60)%60))
	ss=$((u_cpu%60))
	if [ $ss -lt 10 ]
	then
		ss="0$ss"
	fi	
	time="$mm:$ss"
	#echo "$PID|$tty|$pid_stat|$time|$cmd"
	RESULT_DISPLAY="$RESULT_DISPLAY$PID\t$tty\t$pid_stat\t$time\t$cmd\n"
done
echo -e "$RESULT_DISPLAY"
