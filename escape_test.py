s2 = "\n"
import sys
sys.stdout.write(repr(s2) + "
")
sys.stdout.write(str(len(s2)) + "
")
sys.stdout.write(str([hex(ord(c)) for c in s2]) + "
")
