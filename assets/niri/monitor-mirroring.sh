#!/bin/bash

SOURCE="eDP-1"        # Laptop
TARGET="HDMI-A-1"     # External Monitor

if pgrep -x "wl-mirror" > /dev/null
then
  # Example: If laptop is 1920 wide, put HDMI at 1920
  # wlr-randr --output HDMI-A-1 --pos 1920,0

  pkill wl-mirror

else
  # 1. Position HDMI far away (e.g., at pixel 10,000) so the mouse can't reach it
  wlr-randr --output HDMI-A-1 --pos 10000,0 --on

  # 2. Start the mirror and force it to that specific output
  #  (We use --fullscreen-output so it finds the monitor even 
  #  though your mouse can't reach it to drag the window there)
  wl-mirror --fullscreen-output "$TARGET" -s fit "$SOURCE"
  # Mirror SOURCE to TARGET, auto-fullscreen on TARGET, scale to fit
fi
