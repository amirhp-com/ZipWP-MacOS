#!/bin/bash
: '
/*
 * @Author: Amirhossein Hosseinpour <https://amirhp.com>
 * @Date Created: 2024/03/05 13:09:09
 * @Version: 1.3.0
 * @Last modified by: amirhp-com <its@amirhp.com>
 * @Last modified time: 2024/07/14 10:00:39
 */
'

# Check if an argument is provided
if [[ $# -eq 0 ]]; then
  osascript -e "display notification \"No folder path provided.\" with title \"ZipWP Plugin\" subtitle \"\" sound name \"frog\""
  exit 1
fi

# Retrieve the folder path from the first argument
folder=$1
parent_folder_name=$(basename "$folder")

# Function to extract version from PHP file
extract_version() {
    local file_path=$1
    # Use grep and regex to find the version in the plugin header
    version=$(grep -E "^[[:space:]]*[*]*[[:space:]]*Version:[[:space:]]*[0-9a-zA-Z\.\-]+" "$file_path" | awk -F 'Version:[[:space:]]*' '{print $2}' | tr -d -c '[:alnum:].')
    echo -n "$version"
}

# Check if PHP file with the same name as parent folder exists
php_file="$folder/$parent_folder_name.php"
if [ -f "$php_file" ]; then
    echo "Found PHP file with the same name as the parent folder: $php_file"
else
    # Find the first PHP file in the root of the directory
    php_file=$(find "$folder" -maxdepth 1 -name "*.php" | head -n 1)
    if [ -z "$php_file" ]; then
        osascript -e "display notification \"No PHP file found in the root of the directory\" with title \"ZipWP Plugin\" subtitle \"\" sound name \"frog\""
        exit 1
    fi
fi

# Extract and print the version
version=$(extract_version "$php_file")
if [ -z "$version" ]; then
  version="1.0.0";
fi

userInput=$(osascript -e "display dialog \"Enter version number:\" default answer \"$version\" with icon caution with title \"ZipWP Plugin\" " -e 'try' -e 'text returned of result' -e 'on error' -e 'return 1' -e 'end try')

# Check if the user canceled the dialog
if [ $? -ne 0 ]; then
  exit
fi

# Check if the input is empty
if [ -z "$userInput" ]; then
  exit
fi

# Get the name of the selected folder
folder_name=$(basename "$folder")

# Create a temporary directory
temp_dir=$(mktemp -d)

# Move the contents of the selected folder to the temporary directory
cp -R "$folder"/* "$temp_dir"

# Change directory to the temporary directory
cd "$temp_dir" || exit

# Remove .DS_Store files from all folders
find "$temp_dir" -name ".DS_Store" -type f -delete

# Create a parent folder with the selected folder's name
mkdir "$folder_name"

# Move all files and folders into the parent folder
mv * "$folder_name"/

# Zip the parent folder
zip -r "$folder-v$userInput.zip" "$folder_name" -x ".git*" -x ".vscode*" -x ".DS_Store" -x ".VSCodeCounter" -x "index.html" -x "index.php" -x "jsconfig.json"

# if [ $? -ne 0 ]; then
#   osascript -e "display notification \"Your process encountered an error.\" with title \"ZipWP Plugin\" subtitle \"Process Failed\" sound name \"frog\""
# fi

if [ $? -eq 0 ]; then
  osascript -e "display notification \"Your process has completed successfully.\" with title \"ZipWP Plugin\" subtitle \"\" sound name \"frog\""
else
  osascript -e "display notification \"Your process encountered an error.\" with title \"ZipWP Plugin\" subtitle \"\" sound name \"frog\""
fi

# Reveal the created zip archive file in Finder
open -R "$folder-v$userInput.zip"

# Clean up the temporary directory
rm -rf "$temp_dir"
