polkit-default-privs
====================

This repository contains documentation, configuration and programs for
implementing different polkit security profiles in SUSE Linux distributions.

[polkit](https://www.freedesktop.org/software/polkit/docs/latest/polkit.8.html)
is a security framework that allows applications to authenticate privileged
operations. The details of authentication can be configured in a fine-grained
way via polkit policies and rules. While all this is fine feature wise polkit
is not known for its user friendliness.

To help users to configure different security levels, polkit-default-privs
provides a mechanism to switch between sets of predefined polkit security
settings that are targeted towards different usage scenarios. For detailed
information please refer to the shipped man pages.

This is a short overview of the elements contained in this repository:

- The `chkstat` and `set_polkit_default_privs` scripts perform runtime
  configuration of selected polkit profiles.
- The files in the profile directory contain the actual polkit rules for
  actions in the different security profiles.
- The sysconfig file contains a configuration template that will be merged
  into /etc/sysconfig/security during rpm installation. These configuration
  values determine the behaviour of `chkstat` and `set_polkit_default_privs`.

The Makefile is used to build documentation and install files in an
installation root. This is used to package the files in an openSUSE package
found in `Base:System/polkit-default-privs` on <https://build.opensuse.org>.

polkit-default-privs is also used as a whitelisting mechanism in SUSE Linux
distributions to prevent new polkit actions to enter the distribution without
a code review. Only packages that have an entry in the polkit-default-privs
profiles will be considered whitelisted.

The polkit-default-privs are part of the base installation of all SUSE Linux
distributions. This means that the polkit settings in SUSE Linux distributions
often diverge from defaults shipped by upstream developers, depending on the
settings in our profiles and the profile selected by the administrator of a
system. Sadly upstream software is not always well prepared to deal with
diverging polkit settings which can lead to a bad user experience or even
broken software in extreme cases. We are trying to catch theses cases and
patch our packages or improve upstream code.

rules.d whitelisting
--------------------

Polkit uses Java Script snippets to allow customization of the authentication
process. Additional rule files can be installed in `/etc/polkit-1/rules.d` and
`/usr/share/polkit-1/rules.d`. These files are independent of the polkit
profiles implemented by polkit-default-privs. Therefore a separate
whitelisting for them is managed in this repository found in
`etc/polkit-rules-whitelist.json`. This whitelist is used by SUSE
rpmlint-checks to determine valid additions to those directories.

Maintainer
----------

The current maintainer of polkit-default-privs is the SUSE security team
reachable by email via security@suse.com. If you have an issue then please
open a bug via bugzilla.suse.com, assigning it to security-team@suse.de.
