#!/bin/bash

# Get current folder
root=$(pwd)

# Source location
repo_url="https://github.com/home-assistant/core"
repo_branch="dev"
repo_folder="homeassistant/components/synology_dsm"
source_temp_target="$root/synology_dsm_temp"

# Replace with your desired target directory
components_dir="$root/custom_components"
target_dir="$components_dir/custom_synology_dsm"


# Stage 0 - Check tools and clean environment
# Check if jq is installed
command -v jq >/dev/null 2>&1 || { echo >&2 "jq is not installed. Please install jq and try again."; exit 1; }

echo "Removing old folders"
if [ -d "$source_temp_target" ]; then rm -rf $source_temp_target; fi
if [ -d "$target_dir" ]; then rm -rf $target_dir; fi


#Stage 1 - Get the Git repo
# Clone the Git repository
echo "Cloneing git repo $repo_url:$repo_branch"
git clone --depth 1 --filter=blob:none --sparse $repo_url $source_temp_target > /dev/null 2>&1
cd $source_temp_target
git sparse-checkout add $repo_folder > /dev/null 2>&1
cd $root

# Check if cloning was successful
if [[ $? -ne 0 ]]; then
  echo "Error: Failed to clone the Git repository."
  rm -rf $source_temp_target  # Clean up the temporary clone directory
  exit 1
fi
echo "Clone Successful"

# Stage 2 - Build the folder structure required.
mv "$source_temp_target/$repo_folder" "$target_dir/"
rm -rf $source_temp_target

# Stage 3 - Edit the Files
# Stage 3a - Bump the version
. $root/bump_version.sh
ver=$(cat $root/version.txt)

# Update the manifest.json with version
echo "Updating manifest.json"
VER="1.0.$ver" jq '. | .version = env.VER' "$target_dir/manifest.json" > "$target_dir/manifest.json.tmp"
mv "$target_dir/manifest.json.tmp" "$target_dir/manifest.json"

# Update the manifest with other info.
jq '.name = "Custom Synology DSM"' "$target_dir/manifest.json" > "$target_dir/manifest.json.tmp"
mv "$target_dir/manifest.json.tmp" "$target_dir/manifest.json"
jq '.domain = "custom_synology_dsm"' "$target_dir/manifest.json" > "$target_dir/manifest.json.tmp"
mv "$target_dir/manifest.json.tmp" "$target_dir/manifest.json"
jq '.codeowners = ["@ab623"]' "$target_dir/manifest.json" > "$target_dir/manifest.json.tmp"
mv "$target_dir/manifest.json.tmp" "$target_dir/manifest.json"
jq '.issuetracker = "https://github.com/ab623/customhasssynology/issues"' "$target_dir/manifest.json" > "$target_dir/manifest.json.tmp"
mv "$target_dir/manifest.json.tmp" "$target_dir/manifest.json"

# Update the __init__.py
echo "Updating __init__.py"
sed -i '/api = SynoApi/a\ \ \ \ api._with_security = False' "$target_dir/__init__.py"

echo "Success!!"