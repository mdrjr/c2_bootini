install:
	mkdir -p /usr/share/bootini
	install boot.ini /usr/share/bootini
	install boot.ini.default /usr/share/bootini
	install bootini-persistence.pl /usr/share/bootini
	install c2_init.sh /etc/initramfs-tools/scripts/local-top
	install aml_fix_display /bin
	mkdir -p /usr/share/lightdm/lightdm.conf.d
	install 10-odroidc2.conf /usr/share/lightdm/lightdm.conf.d
	install 10-odroid.rules /etc/udev/rules.d
	install blacklist-spi.conf /etc/modprobe.d
