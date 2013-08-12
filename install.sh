#!/bin/bash
if [ $(whoami) = 'root' ]
	then
		cp handshaker.sh /usr/bin/handshaker
		echo 'cp handshaker.sh /usr/bin/handshaker'
		chmod +x /usr/bin/handshaker
	else
		sudo cp handshaker.sh /usr/bin/handshaker
		echo 'sudo cp handshaker.sh /usr/bin/handshaker'
		sudo chmod +x /usr/bin/handshaker
fi
tput setab 2;echo " [*] Handshaker installed ";tput setab 9
