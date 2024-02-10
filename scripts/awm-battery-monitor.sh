#!/bin/bash

flag=0
while [ 1 ]; do
  var=$(upower -i /org/freedesktop/UPower/devices/battery_BAT0| grep -E "percentage"| grep -o '[0-9]*')
  if [ $var -lt 11 ] && [ $flag -eq 0 ]; then
    sudo {$XDG_CONFIG_HOME}/awesome/scripts/awm-suspend.sh
    flag=1
  elif [ $var -gt 11 ] && [ $flag -eq 1 ]; then
    flag=0
  fi
  sleep 120
done
