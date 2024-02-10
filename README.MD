# PI Configuration of Awesomewm

# Work in progress !

This documentation is not finalized…

## System dependencies

* dbus-x11
* dbus-bin
* pipewire
* pipewire-audio
* rofi
* xbindkeys
* cmst (optional)
* gnome-keyring-daemon (optional)
* xfce4-power-manager (optional)


* apparmor-notify (with sudo allowed without password of aa-notify)

## Note about Alt+F2

The key binding `Alt+F2` launch [Rofi](https://github.com/davatorium/rofi) and this key binding is defined
in the file `.xbindkeysrc`.
With this method, even if Awesome failed to load the
configuration file, this uncountable key binding works.
