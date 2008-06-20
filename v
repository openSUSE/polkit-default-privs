#!/bin/sh

exec ./listpolicies.pl $RPM_BUILD_ROOT/usr/share/PolicyKit/policy/* -- polkit-permissions.secure
