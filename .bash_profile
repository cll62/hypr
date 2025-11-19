[[ -f ~/.bashrc ]] && . ~/.bashrc
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
  exec uwsm start hyprland >> ~/.cache/hyprland.log 2>&1
fi