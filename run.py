#!/usr/bin/env python3
import sys
import tty
import os
import shutil

JEPL_PATH = os.environ.get("JEPL_PATH") or os.path.dirname(os.path.realpath(__file__))
janet_executable = shutil.which("janet")
tty.setcbreak(sys.stdin.fileno())
os.execv(janet_executable, [janet_executable, os.path.join(JEPL_PATH, "jepl.janet")])
