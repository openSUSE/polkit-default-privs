DESTDIR=
sbindir=/sbin
sysconfdir=/etc
fillupdir=/var/adm/fillup-templates

all:

install:
	install -d $(DESTDIR)$(sbindir)/conf.d $(DESTDIR)$(sysconfdir)
	install -d $(DESTDIR)$(sysconfdir)/polkit-default-privs.d
	install -m 755 set_polkit_default_privs $(DESTDIR)$(sbindir)/conf.d
	install -m 755 chkstat-polkit $(DESTDIR)$(sbindir)
	install -m 644 polkit-default-privs.{standard,restrictive,local} $(DESTDIR)$(sysconfdir)
	install -m 644 sysconfig.security-polkit_default_privs $(DESTDIR)$(fillupdir)
