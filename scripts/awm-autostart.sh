#!/bin/bash

SCRIPT_PATH="${BASH_SOURCE[0]}"
SCRIPT_DIR=$(dirname $SCRIPT_PATH)

run() {
    if ! pgrep -f "$1"; then
        "$@" &
    fi
}

## Usage
### run "command" option1 optio2…

run "notify-send" -u normal -t 2000 "$SCRIPT_PATH<br><span color='#57dafd' font='26px'>Awesome is launched</span>" -i $SCRIPT_DIR/../awesome-wm-widgets/battery-widget/spaceman.jpg
