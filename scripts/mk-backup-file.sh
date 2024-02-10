#!/bin/bash

## If path (file or directory) $1 exists, move it to $1_old_piawm_CURRENT_DATE
## If path $1 is a symlink, remove it !

[ ! -e "$1" ] && exit 0

if [ -L "$1" ]; then
  echo "Removing symlink $1"
  rm $1
else
  [ -f "$1" ] || [ -d "$1" ] && {
	  BCK_PATH="$1_old_piawm_$(date +'%Y-%m-%d_%H-%M-%S')"
    echo "Moving $1 to $BCK_PATH"
    mv "$1" "$BCK_PATH"
  } || true
fi
