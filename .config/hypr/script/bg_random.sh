#!/bin/bash

IMAGE_FOLDER="$HOME/wallpapers/"
MATUGEN_CONFIG="$HOME/.config/matugen/config.toml"

random_image=$(find "$IMAGE_FOLDER" -type f | shuf -n 1)

swww img "$random_image"
cp "$random_image" "$IMAGE_FOLDER/wall"
matugen image -c "$MATUGEN_CONFIG" "$random_image"
