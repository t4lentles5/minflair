#!/usr/bin/env python3
import getpass
import os
import sys

try:
    import pam
except ImportError:
    print("Error: python-pam is not installed. Please install it.")
    sys.exit(1)


def authenticate(password):
    p = pam.pam()
    username = getpass.getuser()
    return p.authenticate(username, password)


if __name__ == "__main__":
    if len(sys.argv) > 1:
        password = sys.argv[1]
    else:
        password = sys.stdin.readline().rstrip("\r\n")

    if authenticate(password):
        sys.exit(0)
    else:
        sys.exit(1)
