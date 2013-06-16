#! /bin/bash

echo "Start from part 1 or 2 (post-restart) of this script? (1/2): "
read -e STARTFROM

if [ $STARTFROM = 1 ]
then
    #settings
    NEW_STATIC_IP="192.168.1.177"

    ### network setup  ###

    cp -a /etc/network/interfaces /etc/network/interfaces.$(date +%Y%m%d-%H%M)

    # add(append) google nameserver and create static IP
    # first, blank out file
    cat /dev/null > /etc/network/interfaces
    # print new contents
    printf '%s\n' "auto lo

    iface lo inet loopback

    allow-hotplug wlan0
    iface wlan0 inet manual
    wpa-roam /etc/wpa_supplicant/wpa_supplicant.conf

    auto eth0
    iface eth0 inet static
    #your static IP
    address $NEW_STATIC_IP
    #your gateway IP
    gateway 192.168.1.1
    netmask 255.255.255.0
    #your network address \"family\"
    network 192.168.1.0
    dns-nameservers 8.8.8.8 8.8.4.4
    " >> /etc/network/interfaces
    read -p "Locked to static IP to $NEW_STATIC_IP so take note. Press Enter to move on."


    # open up raspbian config
    read -p "Now the raspi-config is going to be opened for you to expand_rootfs to fill entire sd card.

    Don't restart it yet, wait until this script finishes.
    Press enter to continue."

    raspi-config

    # todo: make a stopping point here and reboot. when script runs second time, start from here.
    # for now...
    read -p "Reboot please. Then start the script again, and run part 2. Press Enter to reboot"
    reboot

elif [ $STARTFROM = 2 ]
then

    echo "Adding AutoStatic's RPi repository..."
    # force ipv4 to resolve autostatic.com
    wget -4 -O - http://rpi.autostatic.com/autostatic.gpg.key | apt-key add -
    wget -4 -O /etc/apt/sources.list.d/autostatic-audio-raspbian.list http://rpi.autostatic.com/autostatic-audio-raspbian.list

    echo "Running apt-get update..."
    apt-get update
    echo "Installing Jack and friends"
    apt-get --reinstall install xauth # to make x11 forwarding work
    echo "jackd1 jackd/tweak_rt_limits boolean true"|debconf-set-selections
    #DEBCONF_FRONTEND=noninteractive apt-get --no-install-recommends install jackd1
    apt-get --no-install-recommends -y install jackd1 libcanberra-gtk-module guitarix qjackctl aj-snapshot
    
    echo "disabling onboard sound card..."
    # -i is for in stream editing
    sed -i 's/snd\-bcm2835/#snd\-bcm2835/g'  /etc/modules

    echo "setting default sound card to usb..."
    sed -i 's/snd\-usb\-audio\ index\=\-2/snd\-usb\-audio\ index\=0/g' /etc/modprobe.d/alsa-base.conf

    echo "forcing usb 1.1 and turning off turbo mode on eth..."
    # has to prepend to front of file 
    sed -i '1s/^/dwc_otg\.speed\=1\ smsc95xx\.turbo_mode\=N\ /' /boot/cmdline.txt

    # copy the custom config.txt to /boot
    cp /boot/config.txt /boot/config.txt.$(date +%Y%m%d-%H%M)
    cp ./ampbrownie/config_ampbrownie.txt /boot/config.txt

    # copy the guitarix configs and settings to the right place
    mkdir -p /root/.config/guitarix/plugins
    cp -a ./ampbrownie/gx_head_rc /root/.config/guitarix/
    cp -a ./ampbrownie/ampbrownie.gx /root/.config/guitarix/plugins/


    # install init scripts so AmpBrownie starts up on boot
    # rc.local, and under root is the only I have got it to work at startup
    # first, blank out file
    cat /dev/null > /etc/rc.local
    # print new contents
 printf '%s\n' "#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will \"exit 0\" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.

# Print the IP address
# erm...Put that back in later....


#start jack, then guitarix
/usr/bin/jackd -P70 -p16 -t2000 -d alsa -dhw:CODEC -X seq -p 128 -n 3 -r 44100 -s &
guitarix -N

exit 0
    " >> /etc/rc.local


    echo "Setup has finished. You will want to:
         - reboot and remove your keyboard and mouse
	 - have your guitar/soundcard/midi controller hooked up
         - play some sweet tunes
         use \"sudo reboot\" to reboot now." 
   
else
    echo "Input not recognized, try again."
fi
