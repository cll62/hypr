#!/bin/bash

IMAGE_FOLDER="$HOME/wallpapers/"

random_image=$(find "$IMAGE_FOLDER" -type f | shuf -n 1)

swww img "$random_image"
#swaybg -i "$random_image"
