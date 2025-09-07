#!/bin/bash

IMAGE_FOLDER="$HOME/wallpapers/"

random_image=$(find "$IMAGE_FOLDER" -type f | shuf -n 1)

swww img "$random_image"
cp "$random_image" "$IMAGE_FOLDER/wall"
