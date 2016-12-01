install:
	mkdir -p /usr/share/bootini
	install boot.ini /usr/share/bootini
	install boot.ini.default /usr/share/bootini
	install bootini-persistence.pl /usr/share/bootini
	ln -s /usr/share/bootini/bootini-persistence.pl /usr/bin/bootini
	install c2_init.sh /etc/initramfs-tools/scripts/local-top
	install 10-odroid.rules /etc/udev/rules.d
	install blacklist-spi.conf /etc/modprobe.d
	