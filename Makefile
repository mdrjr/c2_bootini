install:
	mkdir -p /usr/share/bootini
	install boot.ini /usr/share/bootini
	install c2_init.sh /etc/initramfs-tools/scripts/local-top
	install aml_fix_display /bin
	install 10-odroidc2.conf /usr/share/lightdm/lightdm.conf.d