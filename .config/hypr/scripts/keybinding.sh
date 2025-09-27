#!/bin/bash

dynamic_bindings() {
  hyprctl -j binds |
    jq -r '.[] | {modmask, key, keycode, description, dispatcher, arg} | "\(.modmask),\(.key)@\(.keycode),\(.description),\(.dispatcher),\(.arg)"' |
    sed -r \
      -e 's/null//' \
      -e 's,~/.local/share/omarchy/bin/,,' \
      -e 's,uwsm app -- ,,' \
      -e 's/@0//' \
      -e 's/,@/,code:/' \
      -e 's/,code:10,/,1,/' \
      -e 's/,code:11,/,2,/' \
      -e 's/,code:12,/,3,/' \
      -e 's/,code:13,/,4,/' \
      -e 's/,code:14,/,5,/' \
      -e 's/,code:15,/,6,/' \
      -e 's/,code:16,/,7,/' \
      -e 's/,code:17,/,8,/' \
      -e 's/,code:18,/,9,/' \
      -e 's/,code:19,/,0,/' \
      -e 's/,code:20,/,-,/' \
      -e 's/,code:21,/,=,/' \
      -e 's/^0,/,/' \
      -e 's/,mouse:272,/,MOUSE LEFT,/' \
      -e 's/,mouse:273,/,MOUSE RIGHT,/' \
      -e 's/^1,/SHIFT,/' \
      -e 's/^4,/CTRL,/' \
      -e 's/^5,/SHIFT CTRL,/' \
      -e 's/^8,/ALT,/' \
      -e 's/^9,/SHIFT ALT,/' \
      -e 's/^12,/CTRL ALT,/' \
      -e 's/^13,/SHIFT CTRL ALT,/' \
      -e 's/^64,/SUPER,/' \
      -e 's/^65,/SUPER SHIFT,/' \
      -e 's/^68,/SUPER CTRL,/' \
      -e 's/^69,/SUPER SHIFT CTRL,/' \
      -e 's/^72,/SUPER ALT,/' \
      -e 's/^73,/SUPER SHIFT ALT,/' \
      -e 's/^76,/SUPER CTRL ALT,/' \
      -e 's/^77,/SUPER SHIFT CTRL ALT,/'
}   # ← eksik olan bu kapanıştı

parse_bindings() {
  awk -F, '
  {
    key_combo = $1 " + " $2;
    gsub(/^[ \t]*\+?[ \t]*/, "", key_combo);
    gsub(/[ \t]+$/, "", key_combo);

    action = $3;

    if (action == "") {
      for (i = 4; i <= NF; i++) {
        action = action $i (i < NF ? "," : "");
      }
      sub(/,$/, "", action);
      gsub(/(^|,)[[:space:]]*exec[[:space:]]*,?/, "", action);
      gsub(/^[ \t]+|[ \t]+$/, "", action);
      gsub(/[ \t]+/, " ", key_combo);

      gsub(/&/, "\\&amp;", action);
      gsub(/</, "\\&lt;", action);
      gsub(/>/, "\\&gt;", action);
      gsub(/"/, "\\&quot;", action);
      gsub(/'"'"'/, "\\&apos;", action);
    }
    if (action != "") {
      printf "%-35s → %s\n", key_combo, action;
    }
  }'
}

dynamic_bindings |
  sort -u |
  parse_bindings |
  rofi -dmenu -i -theme "$HOME/.config/rofi/launchers/type-1/style-6"
  