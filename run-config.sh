#!/usr/bin/env sh

echo "Checking FreeBSD updates..."
freebsd-update fetch install
portsnap fetch extract update
pkg upgrade -y

HAS_VBOX=`dmesg | grep VBOX | wc -l`
if [ $HAS_VBOX ]; then
	echo "VBox found."
	echo "Installing VBox Guest..."
	pkg install -y virtualbox-ose-additions
	echo "Adding VBox Guest Services..."
	cat rc-vbox.conf >> /etc/rc.conf
	echo "Coping VBox conf settings..."
	cat loader-vbox.conf >> /boot/loader.conf
else
	echo "VBox not found."
fi

echo "Installing Port Management Tools and Shells..."
pkg install -y portmaster portupgrade sudo git bash

echo "Installing Development Tools..."
pkg install -y R cmake gawk gcc gmake lua53 octave sox 

read -p "Select Destktop Environments [Mate/Openbox/Xfce]?" deopt </dev/tty
case "$deopt" in
  m|M) echo "Mate is selected."
	DE_OPT=mate
    ;;
  o|O) echo "Openbox is selected."
	DE_OPT=openbox
    ;;
  x|X) echo "Xfce is selected."
	DE_OPT=xfce
    ;;
  *) echo "Skip to install."
    ;;
esac

if [ $DE_OPT ]; then
	echo "Installing ${DE_OPT}..."
	pkg install -y xorg slim $DE_OPT
	DE_INSTALLED=true
fi

if [ $DE_INSTALLED ]; then
	echo "Adding Destktop Environment Services..."
	cat rc-de.conf >> /etc/rc.conf

	echo "Adding Login Manager..."
	if [ $DE_OPT == "mate" ];
		echo "exec /usr/local/bin/mate-session" > ~/.xinitrc
	elif [ $DE_OPT == "openbox" ];
		echo "exec /usr/local/bin/openbox-session" > ~/.xinitrc
	elif [ $DE_OPT == "xfce" ];
		echo "exec /usr/local/bin/startxfce4 --with-ck-launch" > ~/.xinitrc
	fi

	echo "Installing Desktop Applications..."
	pkg install -y cursor-dmz-theme setxkbmap xrandr dpkg fusefs-ntfs fusefs-ext4fuse py27-gobject py27-webkitgtk py27-pexpect py27-python-distutils-extra rsync gksu octopkg transmission dconf-editor firefox firefox-i18n geany
fi

echo "Coping /boot/loader.conf tunings..."
cat loader-tuning.conf >> /boot/loader.conf

echo "Coping /etc/sysctl.conf tunings..."
cat sysctl-tuning.conf >> /etc/sysctl.conf

echo "Toggling Other Services..."
cat rc-misc.conf >> /etc/rc.conf

ARCH=`uname -m`
echo "Installing Linux Services..."
kldload linux
kldstat
if [ $ARCH == "amd64" ]; then
	echo "Coping /etc/make.conf c6_64 settings..."
	cat make-linux64.conf >> /etc/make.conf
	cd /usr/ports/emulators/linux-c6
	make config-recursive
	portmaster -PP linux-c6
	LINUX_INSTALLED=true
else
	pkg install -y linux-c6
	LINUX_INSTALLED=true
fi

if [ $LINUX_INSTALLED ]; then
	echo "Adding Linux Services..."
	cat rc-linux.conf >> /etc/rc.conf
	if [ $ARCH == "amd64" ]; then
		echo 'linux64_enable="YES"' >> /etc/rc.conf
	fi
fi

echo "Installing GhostBSD ports..."
git clone https://github.com/GhostBSD/ports /tmp/ghostbsd-ports
echo "Installing NetworkMgr..."
cd /tmp/ghostbsd-ports/net-mgmt/networkmgr && make install clean




