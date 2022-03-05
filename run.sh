#!/bin/bash

set -eu

# We know that all of the inputs are base64-encoded, and "|" is not a valid base64 character, so therefore it
# cannot possibly be included in the stdin.
IFS="|" read -a PARAMS <<< $(cat | sed -e 's/__76a7143569c7498988ed9f9c5748352c_TF_MAGIC_SEGMENT_SEPARATOR/|/g')

_content=$(echo "${PARAMS[1]}" | base64 --decode)
_filename=$(echo "${PARAMS[2]}" | base64 --decode)
_is_base64=$(echo "${PARAMS[3]}" | base64 --decode)
_file_permissions=$(echo "${PARAMS[4]}" | base64 --decode)
_directory_permissions=$(echo "${PARAMS[5]}" | base64 --decode)
_directory=$(echo "${PARAMS[6]}" | base64 --decode)
_append=$(echo "${PARAMS[7]}" | base64 --decode)

if [ "$_is_base64" = "true" ]; then
    _content=$(echo "$_content" | base64 --decode)
fi

# Create the parent directories if necessary
mkdir -p -m "$_directory_permissions" "$_directory"

# Store the content in the file
if [ "$_append" = "true" ]; then
    echo -n "$_content" >> "$_filename"
else
    echo -n "$_content" > "$_filename"
fi

# Set permissions on the file
chmod "$_file_permissions" "$_filename"

# We must return valid JSON in order for Terraform to not lose its mind
echo -n "{}"
