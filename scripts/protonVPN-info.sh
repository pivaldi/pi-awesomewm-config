#!/bin/bash

[ -e /tmp/protonvpnstarting ] && {
    echo '<fn=2><fc=#FFFF00>Waiting</fc></fn>'
    exit 0
}

PROTON_VPN_CMD='/home/pi/bin/protonvpn'
PROTON_STATUS="$($PROTON_VPN_CMD s)"
XMOBAR_PROTON_INFO_FAILED_FILE_PATH=/tmp/xmobarProtonInfoFailed

{
    echo "$PROTON_STATUS" | grep -q 'Connected'
} && {
    echo '<fn=2><fc=#00FF00>⚛</fc></fn>'
    [ -e $XMOBAR_PROTON_INFO_FAILED_FILE_PATH ] && {
        rm $XMOBAR_PROTON_INFO_FAILED_FILE_PATH
        notify-send -u normal -t 60000 -i info 'Proton VPN' "Proton VPN Working at $(date)"
    }

    true
} || {
    [ -e $XMOBAR_PROTON_INFO_FAILED_FILE_PATH ] || {
        hostname | grep -q t590 && {
            sleep 10
            PROTON_STATUS="$($PROTON_VPN_CMD s)"
            echo "$PROTON_STATUS" | grep -q 'Connected' || {
                notify-send -u normal -t 6000000 -i error 'Proton VPN' "Proton VPN is not Working at $(date)\n$PROTON_STATUS"
                touch $XMOBAR_PROTON_INFO_FAILED_FILE_PATH
                # sudo protonvpn r || {
                #     sleep 10
                #     sudo protonvpn c --fastest
                # }
            }
        }
    }

    echo '<fn=2><fc=#FF0000>☠</fc></fn>'
}
