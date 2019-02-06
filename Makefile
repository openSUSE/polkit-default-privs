DESTDIR=
sbindir=/sbin
sysconfdir=/etc
fillupdir=/var/adm/fillup-templates
mandir=/usr/share/man

manpages = man/set_polkit_default_privs.8 man/polkit-default-privs.5

all: mans

mans: $(manpages)

.txt.8 .txt.5:
	a2x -f manpage $<

install:
	install -d $(DESTDIR)$(sbindir)  $(DESTDIR)$(sysconfdir) $(DESTDIR)$(fillupdir)
	install -d $(DESTDIR)$(sysconfdir)/polkit-default-privs.d
	install -m 755 src/set_polkit_default_privs $(DESTDIR)$(sbindir)
	install -m 755 src/chkstat-polkit $(DESTDIR)$(sbindir)
	install -m 644 profiles/polkit-default-privs.{easy,standard,restrictive,local} $(DESTDIR)$(sysconfdir)
	install -m 644 etc/sysconfig.security-polkit_default_privs $(DESTDIR)$(fillupdir)
	@for src in $(manpages); do \
		page=`basename $$src` \
		s=$${src##*.}; \
		install -d -m 755 $(DESTDIR)$(mandir)/man$$s; \
		set -- install -m 644 $$src $(DESTDIR)$(mandir)/man$$s/$$page; \
		echo $$@; \
		"$$@"; \
	done

.SUFFIXES: .8 .5 .txt

.PHONY: all mans install package
