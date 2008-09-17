DESTDIR=
sbindir=/sbin
sysconfdir=/etc
fillupdir=/var/adm/fillup-templates
mandir=/usr/share/man

manpages = set_polkit_default_privs.8 polkit-default-privs.5

all: mans

mans: $(manpages)


.txt.8 .txt.5:
	a2x -f manpage $<

install:
	install -d $(DESTDIR)$(sbindir)  $(DESTDIR)$(sysconfdir) $(DESTDIR)$(fillupdir)
	install -d $(DESTDIR)$(sysconfdir)/polkit-default-privs.d
	install -m 755 set_polkit_default_privs $(DESTDIR)$(sbindir)
	install -m 755 chkstat-polkit $(DESTDIR)$(sbindir)
	install -m 644 polkit-default-privs.{standard,restrictive,local} $(DESTDIR)$(sysconfdir)
	install -m 644 sysconfig.security-polkit_default_privs $(DESTDIR)$(fillupdir)
	@for i in $(manpages); do \
		s=$${i##*.}; \
		install -d -m 755 $(DESTDIR)$(mandir)/man$$s; \
		set -- install -m 644 $$i $(DESTDIR)$(mandir)/man$$s/$$i; \
		echo $$@; \
		"$$@"; \
	done

.SUFFIXES: .8 .5 .txt
