#!/bin/bash

set -x

# Check if a file is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <psd_file>"
    exit 1
fi

# Get the input file name
input_file="$1"

# Check if the input file exists
if [ ! -f "$input_file" ]; then
    echo "Error: File '$input_file' not found."
    exit 1
fi

# Extract the base name of the file (without extension)
base_name=$(basename "$input_file" .psd)

# Create a directory to store the slices
mkdir -p "${base_name}_slices"

# Use ImageMagick to split the PSD into separate PNG files
magick "$input_file" "${base_name}_slices/${base_name}_%03d.png"

echo "PSD file has been split into slices. Check the '${base_name}_slices' directory."
