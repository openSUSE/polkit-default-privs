#!/usr/bin/python3

# vim: ts=4 et sw=4 sts=4 :

import argparse

from pkcommon import *

class DuplicateEntryRemover:

    def __init__(self):
        self.m_parser = argparse.ArgumentParser(
                description = "Removes superfluous duplicate entries from polkit profiles or warns about conflicting ones."
        )


    def run(self):
        self.m_args = self.m_parser.parse_args()

        for profile in PROFILES:

            self.m_lines_to_drop = set()
            self.m_actions_seen = {}

            path = getProfilePath(profile)
            for entry in parseProfile(path):
                self.checkDuplicate(entry)

            if self.m_lines_to_drop:
                self.rewriteProfile(path, self.m_lines_to_drop)
            else:
                print("{}: no entries removed".format(path.name.ljust(35)))


    def checkDuplicate(self, entry):
        seen = self.m_actions_seen.get(entry.action, None)
        if not seen:
            self.m_actions_seen[entry.action] = entry
        else:
            if entry.settings == seen.settings:
                self.m_lines_to_drop.add(entry.linenr)
                print("{}:{}: removing redundant entry with same settings as in line {}".format(
                    entry.path.name.ljust(35),
                    str(entry.linenr).rjust(3),
                    seen.linenr
                ))
            else:
                printerr("{}:{}: {}: conflicting duplicate entry ({}), previously seen in line {} ({})".format(
                    seen.path.name.ljust(35),
                    str(entry.linenr).rjust(3),
                    seen.action,
                    ':'.join(entry.settings),
                    seen.linenr,
                    ':'.join(seen.settings)

                ))


    def rewriteProfile(self, path, lines_to_drop):

        lines = []

        with open(path) as fd:

            for linenr, line in enumerate(fd.readlines(), start = 1):

                if linenr not in lines_to_drop:
                    lines.append(line)

        with open(path, 'w') as fd:
            fd.write(''.join(lines))


if __name__ == '__main__':
    main = DuplicateEntryRemover()
    main.run()
