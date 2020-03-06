DESTDIR=
sbindir=/sbin
sysconfdir=/etc
datadir=/usr/share
fillupdir=/var/adm/fillup-templates
mandir=$(datadir)/man
docdir=$(datadir)/doc/packages

manpages = man/set_polkit_default_privs.8 man/polkit-default-privs.5

all: mans

mans: $(manpages)

.adoc.8 .adoc.5:
	a2x -f manpage $<

clean:
	rm -f man/*.{5,8}

install:
	install -d $(DESTDIR)$(sbindir)  $(DESTDIR)$(sysconfdir) $(DESTDIR)$(fillupdir)
	install -d $(DESTDIR)$(datadir)/polkit-default-privs/{package-overrides.d,profiles}
	install -d $(DESTDIR)$(docdir)/polkit-default-privs
	install -m 755 src/set_polkit_default_privs $(DESTDIR)$(sbindir)
	install -m 755 src/chkstat-polkit $(DESTDIR)$(sbindir)
	install -m 644 etc/polkit-default-privs.local $(DESTDIR)$(sysconfdir)/
	install -m 644 profiles/* $(DESTDIR)$(datadir)/polkit-default-privs/profiles/
	install -m 644 etc/sysconfig.security-polkit_default_privs $(DESTDIR)$(fillupdir)
	install -m 644 polkit-rules-whitelist.json $(DESTDIR)$(datadir)/polkit-default-privs/
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
