#!/usr/bin/env python

import json
import re
import subprocess
import sys

def get_focused_win_title():
  """ Get the current focused window title. """
  return subprocess.check_output("~/.i3/get_focused_win_title.sh", shell=True).strip('\n')

def get_cpu_temperature():
  """ Get the current CPUs temperature (averate) in Celsius degress. """
  cpu_temp = subprocess.check_output("sensors | grep -i \"core \" | awk -F : '{print $2}' | awk '{print $1}'", shell=True).strip('\n').split('\n')
  cpu_temp_dummy = []
  for cpu in cpu_temp:
    strip = re.sub(r"[^\+\-0-9\.]", "", cpu)
    cpu_temp_dummy.append(strip)
  cpu_temp = map(float, cpu_temp_dummy)
  return int(sum(cpu_temp)/len(cpu_temp))

def get_fan_rpm():
  """ Get the current fans velocity (average) in RMP. """
  fan_rpm = subprocess.check_output("sensors | grep -i \"processor fan\" | awk -F : '{print $2}' | awk '{print $1}'", shell=True).strip('\n').split('\n')
  fan_rpm = map(int, fan_rpm)
  return sum(fan_rpm)/len(fan_rpm)

def print_line(message):
  """ Non-buffered printing to stdout. """
  sys.stdout.write(message + '\n')
  sys.stdout.flush()

def read_line():
  """ Interrupted respecting reader for stdin. """
  # try reading a line, removing any extra whitespace
  try:
    line = sys.stdin.readline().strip()
    # i3status sends EOF, or an empty line
    if not line:
      sys.exit(3)
    return line
  # exit on ctrl-c
  except KeyboardInterrupt:
    sys.exit()

if __name__ == '__main__':
  # Skip the first line which contains the version header.
  print_line(read_line())

  # The second line contains the start of the infinite array.
  print_line(read_line())

  while True:
    line, prefix = read_line(), ''
    # ignore comma at start of lines
    if line.startswith(','):
      line, prefix = line[1:], ','

    j = json.loads(line)
    # insert information into the start of the json, but could be anywhere
    # CHANGE THIS LINE TO INSERT SOMETHING ELSE
    j.insert(0, {'full_text' : '%s' % get_focused_win_title(), 'name' : 'wtitle', 'color' : '#cb4b16'})
    j.insert(1, {'full_text' : 'CPU %s C deg' % get_cpu_temperature(), 'name' : 'cputemp'})
    j.insert(2, {'full_text' : 'FAN %s RPM' % get_fan_rpm(), 'name' : 'fanrmp'})
    # and echo back new encoded json
    print_line(prefix+json.dumps(j))
