HandShaker
==========

Detect, capture and crack handshakes by partial ESSID.

This is script is designed to automate the task of capturing and cracking a WPA/2 EAOPL handshake.

	HandShaker - Detect, deauth, capture and crack WPA/2 handshakes
	
	Usage: handshaker <Method> <Options> [in any order]
	
		Method:
			-a - Autobot or Wardriving mode
			-e - Search for AP by partial unique ESSID
			-l - Scan for APs and present a target list
		Options:
			-i - Wireless Interface card
			-w - Wordlist to use for cracking
			-h - This help
				
	eg. handshaker -e Hub3-F -i wlan0 -w /usr/share/wordlists/rockyou.txt	 - Search for essids like Hub3-F using wlan0 and crack with wordlist
	    handshaker -a -i wlan0 						 - Autobot or wardriving mode using wlan0
