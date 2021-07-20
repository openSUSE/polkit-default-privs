DESTDIR=
sbindir=/sbin
sysconfdir=/usr/etc
fillupdir=/var/adm/fillup-templates
mandir=/usr/share/man
docdir=/usr/share/doc/packages

manpages = man/set_polkit_default_privs.8 man/polkit-default-privs.5

all: mans

mans: $(manpages)

.adoc.8 .adoc.5:
	a2x -f manpage $<

clean:
	rm -f man/*.{5,8}

install:
	install -d $(DESTDIR)$(sbindir)  $(DESTDIR)$(sysconfdir) $(DESTDIR)$(fillupdir)
	install -d $(DESTDIR)$(docdir)/polkit-default-privs
	install -m 755 src/set_polkit_default_privs $(DESTDIR)$(sbindir)
	install -m 755 src/chkstat-polkit $(DESTDIR)$(sbindir)
	install -m 644 profiles/polkit-default-privs.{easy,standard,restrictive,local} $(DESTDIR)$(sysconfdir)
	install -m 644 etc/sysconfig.security-polkit_default_privs $(DESTDIR)$(fillupdir)
	install -m 644 etc/polkit-rules-whitelist.json $(DESTDIR)/etc
	install -m 644 README.md $(DESTDIR)$(docdir)/polkit-default-privs
	@for src in $(manpages); do \
		page=`basename $$src` \
		s=$${src##*.}; \
		install -d -m 755 $(DESTDIR)$(mandir)/man$$s; \
		set -- install -m 644 $$src $(DESTDIR)$(mandir)/man$$s/$$page; \
		echo $$@; \
		"$$@"; \
	done

.SUFFIXES: .8 .5 .adoc

.PHONY: all mans install package
