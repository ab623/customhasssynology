#!/bin/bash

# Get current folder
root=$(pwd)
ver_file=version.txt

# Read the current version from the file
current_version=$(cat $ver_file)
new_version=$(($current_version + 1))

# Write the new version back to the file
echo "$new_version" > $ver_file

echo "New version: $new_version"