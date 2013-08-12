#!/bin/bash
if [ $(whoami) = 'root' ]
	then
		cp handshaker.sh /usr/bin/handshaker
		echo 'cp handshaker.sh /usr/bin/handshaker'
		echo 'chmod +x /usr/bin/handshaker'
		chmod +x /usr/bin/handshaker
	else
		echo 'sudo cp handshaker.sh /usr/bin/handshaker'
		sudo cp handshaker.sh /usr/bin/handshaker
		echo 'sudo chmod +x /usr/bin/handshaker'
		sudo chmod +x /usr/bin/handshaker
fi
echo
tput setab 2;echo " [*] handshaker installed ";tput setab 9
