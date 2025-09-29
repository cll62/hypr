#!/bin/bash
MUSIC_DIR=$(xdg-user-dir MUSIC)
if pgrep -x mpv > /dev/null; then
    pkill -x mpv
else
    mpv --no-video --shuffle "$MUSIC_DIR"/*
fi