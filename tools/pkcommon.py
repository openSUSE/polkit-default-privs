# vim: ts=4 et sw=4 sts=4 :
import sys
from pathlib import Path

PROFILES = ("easy", "standard", "restrictive")
profile_dir = Path(__file__).parent.with_name("profiles")

def printerr(*args, **kwargs):
    kwargs["file"] = sys.stderr
    print(*args, **kwargs)


def getProfilePath(which):
    return profile_dir / which


class ProfileEntry:

    path = ""
    line = ""
    linenr = 0
    action = ""
    settings = tuple()


def parseProfile(path):
    """Parses the profile found in @path and yields each parsed entry as a
    ProfileEntry instance."""

    with open(path) as fd:

        nr = 0

        for line in fd.readlines():
            nr += 1
            line = line.strip()
            if not line or line.startswith('#'):
                continue

            parts = line.split()
            # there can be trailing comments
            action, settings = parts[:2]
            settings = settings.split(':')
            if len(settings) == 1:
                settings = settings * 3

            entry = ProfileEntry()
            entry.path = path
            entry.line = line
            entry.linenr = nr
            entry.action = action
            entry.settings = settings

            yield entry
