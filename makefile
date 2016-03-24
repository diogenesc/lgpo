all: 

install: 

check-root:
	if test `whoami` != "root"; then echo "need to be root"; exit 1;fi

debian: check-root clean compile-sh debuild debconfig debuilder

compile-sh:
	shc -r -f scripts/lgpod.sh
	shc -r -f scripts/lgpo.sh

clean:
	rm -Rf debian
	find scripts/ -iname *.sh.* -exec rm -f {} \;

debuild:
	mkdir -p debian/usr/sbin/
	mkdir -p debian/usr/bin/
	mkdir -p debian/var/lib/lgpo/policys
	mkdir -p debian/usr/share/lgpo/samples/
	mkdir -p debian/etc/
	mkdir -p debian/etc/init.d/
	mkdir -p debian/DEBIAN
	mkdir -p debian/etc/logrotate.d/
	install -m 555 -g root -o root scripts/lgpod.sh.x debian/usr/sbin/lgpod
	install -m 555 -g root -o root scripts/lgpo.sh.x debian/usr/bin/lgpo
	install -m 664 -g root -o root data/lgpo.conf debian/usr/share/lgpo/samples/lgpo.conf
	install -m 664 -g root -o root data/rsyncd.conf debian/usr/share/lgpo/samples/rsyncd.conf
	install -m 664 -g root -o root data/rsyncd.secrets debian/usr/share/lgpo/samples/rsyncd.secrets
	install -m 664 -g root -o root data/debian/control debian/DEBIAN/control
	install -m 755 -g root -o root data/debian/postinst debian/DEBIAN/
	install -m 644 -g root -o root data/logrotate debian/etc/logrotate.d/lgpo
	install -m 755 -g root -o root data/service debian/etc/init.d/lgpo

install: check-root clean compile-sh
	mkdir -p /usr/share/lgpo/samples/
	install -m 555 -g root -o root scripts/lgpod.sh.x /usr/sbin/lgpod
	install -m 555 -g root -o root scripts/lgpo.sh.x /usr/sbin/lgpo
	install -m 664 -g root -o root data/lgpo.conf /usr/share/lgpo/samples/lgpo.conf
	install -m 664 -g root -o root data/rsyncd.conf /usr/share/lgpo/samples/rsyncd.conf
	install -m 644 -g root -o root data/logrotate /etc/logrotate.d/lgpo
	install -m 755 -g root -o root data/service /etc/init.d/lgpo
	install -m 664 -g root -o root data/rsyncd.secrets /usr/share/lgpo/samples/rsyncd.secrets
	systemctl daemon-reload

uninstall:
	rm -f /usr/bin/lgpod
	rm -f /etc/lgpo.conf
	rm -f /usr/share/lgpo/samples/rsyncd.conf
	rm -f /etc/logrotate.d/lgpo
	rm -f /etc/init.d/lgpo
	rm -f /usr/share/lgpo/samples/rsyncd.secrets
	rm -f /usr/bin/lgpo

	rmdir /usr/share/lgpo/samples
	rmdir /usr/share/lgpo

debconfig:
	sed "s:CURRENTVERSION:`cat VERSION`:" -i debian/DEBIAN/control
	sed "s:CURRENTARCH:`cat ARCH`:" -i debian/DEBIAN/control

debuilder:
	dpkg-deb --build  debian/ lgpo-`cat VERSION`_`cat ARCH`_build.deb
	echo "All done! dpkg -i lgpo-`cat VERSION`_`cat ARCH`_build.deb to test. Good Luck!"

