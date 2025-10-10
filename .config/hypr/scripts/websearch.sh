#!/bin/bash

declare -A sites=(
  [chat]="https://chatgpt.com/"
  [git]="https://github.com/cll62"
  [yt]="https://www.youtube.com"
  [ym]="https://music.youtube.com/"
  [mail]="https://mail.google.com/mail/u/0/#inbox"
  [film]="https://hurawatchtv.tv/home"
  [kitap]="https://annas-archive.org/"
  [müzik]="https://open.spotify.com/"
  [math]="https://www.mathcha.io/editor"
  [gemini]="https://gemini.google.com/app"
  [365]="https://m365.cloud.microsoft/search/?refOrigin=Google"
  [whatsapp]="https://web.whatsapp.com/"
  [x]="https://x.com/"
  [grok]="https://grok.com"
  [qwen]="https://chat.qwen.ai/"
  [meb]="https://mebbis.meb.gov.tr/"
)

query=$(rofi -dmenu -theme "$HOME/.config/rofi/websearch.rasi")
[ -z "$query" ] && exit

url=${sites[$query]}
if [ -n "$url" ]; then
  xdg-open "$url"
else
  encoded_query=$(echo "$query" | jq -s -R -r @uri)
  xdg-open "https://www.google.com/search?q=${encoded_query}"
fi
