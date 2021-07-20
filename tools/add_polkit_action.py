#!/usr/bin/python3

# vim: ts=4 et sw=4 sts=4 :

import argparse
import sys

from pkcommon import PROFILES, getProfilePath, parseProfile, printerr

epilog = f"""Example invocation:

# add a single new rule introducing a new group of actions
{__file__} \\
    --new-group "bsc#1165436:backup tool that performs privilege escalation to root" \\
    --action in.teejeetech.pkexec.timeshift \\
    --easy auth_admin:auth_admin:auth_admin_keep \\
    --standard auth_admin \\
    --restrictive auth_admin
"""


class PolkitActionHandler:

    # existing default profiles in increasing order of security
    # existing authentication type settings in increasing order of security
    AUTH_TYPES = ("yes", "auth_self_keep", "auth_self", "auth_admin_keep", "auth_admin", "no")
    AUTH_CATEGORIES = ("any-user", "inactive-session", "active-session")

    def __init__(self):

        self.m_parser = argparse.ArgumentParser(
            description="Adds a new action with associated authentication settings to the polkit profiles managed by polkit-default-privs",
            formatter_class=argparse.RawTextHelpFormatter,
            epilog=epilog
        )

        self.m_parser.add_argument(
            "--new-group",
            metavar="bsc#<bug>:<comment>",
            type=self.parseGroupArg,
            help="Introduces a new group block of related polkit actions. Requires a bug reference and comment string"
        )

        self.m_parser.add_argument(
            "--action",
            help="the canonical action name to add like 'in.teejeetech.pkexec.timeshift'",
            required=True,
            type=self.parseAction
        )

        for profile in PROFILES:

            self.m_parser.add_argument(
                "--" + profile,
                metavar=':'.join(self.AUTH_CATEGORIES),
                type=self.parseAuthTuple,
                help="Specifies the settings for the --action in this profile. If all three fields are equal you may also specify only a single field without colons.",
                required=True
            )

    def parseAuthTuple(self, s):
        s = s.lower()
        if s in self.AUTH_TYPES:
            # the same auth type for all three fields
            # expand to three full fields for easier usage later on
            return [s] * 3

        parts = s.split(':')

        if len(parts) != 3:
            raise argparse.ArgumentTypeError("invalid number of ':' separated fields")

        ret = []

        for part in parts:
            part = part.lower()
            if part not in self.AUTH_TYPES:
                raise argparse.ArgumentTypeError("bad authentication type '{}'".format(part))

            ret.append(part)

        return ret

    def parseGroupArg(self, s):

        parts = s.split(':', 1)

        if len(parts) != 2:
            raise argparse.ArgumentTypeError("missing ':' separator")

        bug, comment = parts

        parts = bug.split('#')

        if len(parts) != 2:
            raise argparse.ArgumentTypeError("missing '#' separator in bug reference")

        prefix, nr = parts
        prefix = prefix.lower()

        allowed_prefixes = ("bsc", "boo")

        if prefix not in allowed_prefixes:
            raise argparse.ArgumentTypeError("invalid bug prefix, expected any of {}".format(allowed_prefixes))

        try:
            nr = int(nr)
        except ValueError:
            raise argparse.ArgumentTypeError("invalid bug number {}".format(nr))

        if len(comment.split("\n")) != 1:
            raise argparse.ArgumentTypeError("newline in comment encountered")

        return (prefix, nr), comment

    def parseAction(self, s):

        # make sure there's no whitespace
        if len(s.split()) != 1:
            raise argparse.ArgumentTypeError("whitespace in action name")

        # should have at least one separator
        if len(s.split('.')) < 2:
            raise argparse.ArgumentTypeError("too few elements in action name")

        return s

    def run(self):

        self.m_args = self.m_parser.parse_args()
        # tuple of auth types matching the profiles
        self.m_auth_types = tuple(getattr(self.m_args, profile) for profile in PROFILES)

        if not self.sanityCheck():
            printerr("Not adding new action since sanity check(s) failed")
            sys.exit(2)

        self.addAction()

    def sanityCheck(self):
        """Perform a couple of sanity checks for the newly added actions. This
        is somewhat redundant to the linter in the security-tools repository
        but these checks can this way be applied right away and they're not
        too complex to make."""

        ret = self.findDuplicateActions()
        ret &= self.checkProfileAuthTypeOrder()
        ret &= self.checkBugNr()

        return ret

    def findDuplicateActions(self):

        ret = True

        for profile in PROFILES:

            path = getProfilePath(profile)

            for entry in parseProfile(path):
                if not self.checkDuplicate(entry):
                    ret = False

        return ret

    def checkDuplicate(self, entry):
        if entry.action == self.m_args.action:
            printerr("ERROR: action to be added already exists in {}:{}".format(
                entry.path, entry.linenr
            ))
            return False

        return True

    def checkProfileAuthTypeOrder(self):
        """Checks that authentication types are not getting weaker in stronger
        profiles."""

        ret = True
        strongest = [self.AUTH_TYPES[0]] * 3

        for profile, auth_types in zip(PROFILES, self.m_auth_types):
            for nr, old, new in zip(range(len(strongest)), strongest, auth_types):

                if self.AUTH_TYPES.index(old) > self.AUTH_TYPES.index(new):
                    printerr("ERROR: Auth type for {} in profile {} is weaker than in profile {}".format(
                        self.AUTH_CATEGORIES[nr],
                        profile,
                        PROFILES[PROFILES.index(profile) - 1]
                    ))
                    ret = False

            strongest = auth_types

        return ret

    def checkBugNr(self):
        """Attempts to verify that a specified bug number really exists."""

        import subprocess
        import shutil

        if not self.m_args.new_group:
            return True

        bug = self.m_args.new_group[0]
        nr = bug[1]

        insect = shutil.which("insect")

        if not insect:
            # cannot check bug validity without some bugzilla CLI, assume it's
            # fine
            return True

        try:
            # don't suppress output, might be a helpful pointer to see the
            # actual bug summary once more on success
            subprocess.check_call(
                [insect, "info", "-1", str(nr)],
                shell=False,
                close_fds=True
            )
        except subprocess.CalledProcessError:
            printerr("ERROR: bug {}#{} doesn't seem to exist".format(*bug))
            return False

        return True

    def addAction(self):

        for profile, auth_settings in zip(PROFILES, self.m_auth_types):

            path = getProfilePath(profile)

            with open(path, 'a') as fd:

                if self.m_args.new_group:
                    bug, comment = self.m_args.new_group
                    fd.write("\n")
                    fd.write("# {} ({}#{})\n".format(
                        comment, *bug
                    ))

                fd.write("{} {}\n".format(
                    self.m_args.action,
                    ':'.join(auth_settings)
                ))


main = PolkitActionHandler()
main.run()
