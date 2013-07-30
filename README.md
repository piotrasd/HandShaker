HandShaker
==========

Detect, capture and crack handshakes by partial ESSID.

This is script is designed to automate the task of capturing and cracking a WPA/2 EAPOL handshake.

Usage: handshaker x y z
  
			x - Partial unique ESSID (required)
			y - Wireless Interface card
			z - path to wordlist to use for cracking
				
	eg. handshaker Hub3-F wlan0 /usr/share/wordlists/rockyou.txt
