#!/bin/bash

sleep 1

printf '\33]50;%s\007' "xft:Terminus:pixelsize=20"
LC_ALL=fr_FR.UTF-8 cal -y
read X
