DESTDIR=
sbindir=/sbin
sysconfdir=/etc

all:

install:
	install -d $(DESTDIR)$(sbindir)/conf.d $(DESTDIR)$(sysconfdir)
	install -d $(DESTDIR)$(sysconfdir)/polkit-permissions.d
	install -m 755 SuSEconfig.polkit-permissions $(DESTDIR)$(sbindir)/conf.d
	install -m 755 polkit-chkstat $(DESTDIR)$(sbindir)
	install -m 644 polkit-permissions.{easy,secure,paranoid,local} $(DESTDIR)$(sysconfdir)
