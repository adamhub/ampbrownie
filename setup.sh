#! /bin/bash

echo "Start from part 1 or 2 (post-restart) of this script? (1/2): "
read -e STARTFROM

if [ $STARTFROM = 1 ]
then
    #settings
    NEW_STATIC_IP="192.168.1.177"

    ### network setup  ###

    cp -a /etc/network/interfaces /etc/network/interfaces.orig.$(date +%Y%m%d-%H%M)

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
    #read -p "Jack install will ask you if you want to adjust things for realtime control. Answer yes to that. Press enter now."
    echo "jackd1 jackd/tweak_rt_limits boolean true"|debconf-set-selections
    #DEBCONF_FRONTEND=noninteractive apt-get --no-install-recommends install jackd1
    apt-get --no-install-recommends -y install jackd1 libcanberra-gtk-module jalv guitarix qjackctl aj-snapshot
    
    echo "disabling onboard sound card..."
    # -i is for in stream editing
    sed -i 's/snd\-bcm2835/#snd\-bcm2835/g'  /etc/modules

    echo "setting default sound card to usb..."
    sed -i 's/snd\-usb\-audio\ index\=\-2/snd\-usb\-audio\ index\=0/g' /etc/modprobe.d/alsa-base.conf

    echo "forcing usb 1.1 and turning off turbo mode on eth..."
    # has to prepend to front of file 
    sed -i '1s/^/dwc_otg\.speed\=1\ smsc95xx\.turbo_mode\=N\ /' /boot/cmdline.txt

    # copy the custom config.txt to /boot
    cp /boot/config.txt /boot/config.txt.orig.$(date +%Y%m%d-%H%M)
    cp ./ampbrownie/config_ampbrownie.txt /boot/config.txt
    #wget -4 -O /boot/config.txt https://raw.github.com/adamhub/ampbrownie/master/config_ampbrownie.txt

    # copy the guitarix configs and settings to the right place
    mkdir -p /home/pi/.config/guitarix/plugins
    cp -a ./ampbrownie/gx_head_rc /home/pi/.config/guitarix/
    cp -a ./ampbrownie/ampbrownie.gx /home/pi/.config/guitarix/plugins/
    #wget -4 -P /home/pi/.config/guitarix https://raw.github.com/adamhub/ampbrownie/master/gx_head_rc
    #wget -4 -P /home/pi/.config/guitarix/plugins https://raw.github.com/adamhub/ampbrownie/master/ampbrownie.gx
    chown -R pi: /home/pi/.config
    chmod -R 777 /home/pi/.config

    # install init scripts so AmpBrownie starts up on boot
    cp -a ./ampbrownie/init_scripts/ampbrownie /etc/init.d/
    #wget -4 -P /etc/init.d https://raw.github.com/adamhub/ampbrownie/master/init_scripts/ampbrownie
    update-rc.d ampbrownie defaults

    echo "Setup has finished. You will want to:
         - reboot and remove your keyboard and mouse
	 - have your guitar/soundcard/midi controller hooked up
         - play some sweet tunes" 

else
    echo "Input not recognized, try again."
fi
