#! /bin/bash

echo "Start from part 1 or 2 of this script? (1/2): "
read -e STARTFROM

if [ $STARTFROM = 1 ]
then
    #settings
    NEW_STATIC_IP="192.168.1.177"

    ### network setup  ###

    # add(append) google nameserver 
    #sudo echo "nameserver 8.8.8.8" >> /etc/resolv.conf
    #echo "Updated named servers...."\n

    # create static ip
    # blank out file
    sudo cat /dev/null > /etc/network/interfaces
    # print new contents
    sudo printf '%s\n' "auto lo

    iface lo inet loopback

    #disable dhcp
    #iface eth0 inet dhcp

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
    read -p "Locked to static IP to $NEW_STATIC_IP so take note....Press Enter now."


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
    read -p "Reboot please...."

elif [ $STARTFROM = 2 ]
then

    echo "Adding Autostatic's ppms..."
    # force ipv4 to resolve autostatic.com
    wget -4 -O - http://rpi.autostatic.com/autostatic.gpg.key | sudo apt-key add -
    sudo wget -4 -O /etc/apt/sources.list.d/autostatic-audio-raspbian.list http://rpi.autostatic.com/autostatic-audio-raspbian.list

    echo "Running apt-get update..."
    sudo apt-get update
    echo "Installing Jack and friends"
    #sudo apt-get install vim
    sudo apt-get --reinstall install xauth # to make x11 forwarding work
    #read -p "Jack install will ask you if you want to adjust things for realtime control. Answer yes to that. Press enter now."
    echo "jackd1 jackd/tweak_rt_limits boolean true"|debconf-set-selections
    sudo DEBCONF_FRONTEND=noninteractive apt-get --no-install-recommends install jackd1
    #sudo apt-get --no-install-recommends install jackd1
    sudo modprobe -r snd-bcm2835
    sudo apt-get install libcanberra-gtk-module
    sudo apt-get install jalv
    sudo apt-get install guitarix
    sudo apt-get install qjackctl
    # a good jack startup script
    wget -4 https://raw.github.com/AutoStatic/scripts/rpi/rpi/jackstart


    ### Prep for realtime audio ###
    echo "increasing shared memory..."
    sudo mount -o remount,size=128M /dev/shm
    #todo, put in jackd startup script

    echo "turning off CPU scaling"
    echo -n performance | sudo tee /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

    echo "disabling onboard sound card..."
    # -ie is for in stream editing
    sudo sed -ie 's/snd\-bcm2835/#snd\-bcm2835/g'  /etc/modules

    echo "setting defualt sound card to usb..."

    sudo sed -ie 's/snd\-usb\-audio\ index\=\-2/snd\-usb\-audio\ index\=0/g' /etc/modprobe.d/alsa-base.conf
    sudo alsa force-reload

    echo "forcing usb 1.1 and turning off turbo mode on eth..."
    # >> means append
    sudo echo "dwc_otg.speed=1 smsc95xx.turbo_mode=N" >> /boot/cmdline.txt

    echo "this script has finished. Reboot, then you can run jackstart, and then jalv... "

    #todo
    #echo "Setting Guitarix/Jackd ect. to startup on boot so you can plug and play..."

    #todo
    #echo "Looks like setup is completed. You can run 'ampbrownie start' or 'ampbrownie stop' as you please.

else
    echo "Input not recognized, try again."
fi
