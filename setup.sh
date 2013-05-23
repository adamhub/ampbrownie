#! /bin/bash

echo "Start from part 1 or 2 (post-restart) of this script? (1/2): "
read -e STARTFROM

if [ $STARTFROM = 1 ]
then
    #settings
    NEW_STATIC_IP="192.168.1.177"

    ### network setup  ###

    # add(append) google nameserver and create static IP
    # first, blank out file
    sudo cat /dev/null > /etc/network/interfaces
    # print new contents
    sudo printf '%s\n' "auto lo

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
    read -p "Now the raspi-config is going to be opened for you to edit.
    Do these two things:

    a) overclock to "medium"
    b) expand_rootfs to fill entire sd card

    Don't restart it yet, wait until this script finishes.
    Press enter to continue."

    sudo raspi-config

    # todo: make a stopping point here and reboot. when script runs second time, start from here.
    # for now...
    read -p "Reboot please. Then start the script again, and run part 2. Press Enter to reboot"
    sudo reboot

elif [ $STARTFROM = 2 ]
then

    echo "Adding AutoStatic's ppa..."
    # force ipv4 to resolve autostatic.com
    wget -4 -O - http://rpi.autostatic.com/autostatic.gpg.key | sudo apt-key add -
    sudo wget -4 -O /etc/apt/sources.list.d/autostatic-audio-raspbian.list http://rpi.autostatic.com/autostatic-audio-raspbian.list

    echo "Running apt-get update..."
    sudo apt-get update
    echo "Installing Jack and friends"
    sudo apt-get --reinstall install xauth # to make x11 forwarding work
    #read -p "Jack install will ask you if you want to adjust things for realtime control. Answer yes to that. Press enter now."
    echo "jackd1 jackd/tweak_rt_limits boolean true"|sudo debconf-set-selections
    #sudo DEBCONF_FRONTEND=noninteractive apt-get --no-install-recommends install jackd1
    read -p "When asked to optimize for realtime, answer yes. Press enter to continue."
    sudo apt-get --no-install-recommends -y install jackd1
    sudo apt-get --no-install-recommends -y install libcanberra-gtk-module
    sudo apt-get --no-install-recommends -y install jalv
    sudo apt-get --no-install-recommends -y install guitarix
    sudo apt-get --no-install-recommends -y install qjackctl
    sudo apt-get --no-install-recommends -y install aj-snapshot
    # is this redundant? 
    sudo modprobe -r snd-bcm2835

        echo "disabling onboard sound card..."
    # -ie is for in stream editing
    sudo sed -ie 's/snd\-bcm2835/#snd\-bcm2835/g'  /etc/modules

    echo "setting default sound card to usb..."
    sudo sed -ie 's/snd\-usb\-audio\ index\=\-2/snd\-usb\-audio\ index\=0/g' /etc/modprobe.d/alsa-base.conf
    sudo alsa force-reload

    echo "forcing usb 1.1 and turning off turbo mode on eth..."
    # has to prepend to front of file 
    sudo sed -i '1s/^/dwc_otg\.speed\=1\ smsc95xx\.turbo_mode\=N\ /' /boot/cmdline.txt

    # copy the guitarrix configs and settings to the right place
    mkdir .config
    mkdir .config/guitarix
    cp ampbrownie/gx_head_rc .config/guitarix/gx_head_rc
    cp ampbrownie/ampbrownie.gx .config/guitarix/plugins/

    # install init scripts so AmpBrownie starts up on boot
    cp ~/ampbrownie/init_scripts/ampbrownie.sh /etc/init.d/ampbrownie.sh
    sudo chmod /etc/init.d/ampbrownie.sh
    sudo update-rc.d ampbrownie.sh defaults

    echo "Setup has finished. You will want to:
         - reboot and remove your keyboard an mouse
	 - have your guitar/soundcard/midi controller hooked up
         - play some sweet tunes" 

else
    echo "Input not recognized, try again."
fi
