#!/bin/bash

set -eu

# We know that all of the inputs are base64-encoded, and "|" is not a valid base64 character, so therefore it
# cannot possibly be included in the stdin.
IFS="|" read -a PARAMS <<< $(cat | sed -e 's/__76a7143569c7498988ed9f9c5748352c_TF_MAGIC_SEGMENT_SEPARATOR/|/g')

_uuid=$(echo "${PARAMS[1]}" | base64 --decode)
_idx="${PARAMS[2]}"
_final=$(echo "${PARAMS[3]}" | base64 --decode)
_tmp_dir=$(echo "${PARAMS[4]}" | base64 --decode)
_content=$(echo "${PARAMS[5]}" | base64 --decode)
_filename=$(echo "${PARAMS[6]}" | base64 --decode)
_is_base64=$(echo "${PARAMS[7]}" | base64 --decode)
_file_permissions=$(echo "${PARAMS[8]}" | base64 --decode)
_directory_permissions=$(echo "${PARAMS[9]}" | base64 --decode)
_directory=$(echo "${PARAMS[10]}" | base64 --decode)
_append=$(echo "${PARAMS[11]}" | base64 --decode)

_seq_file="$_tmp_dir/$_uuid.seq"

# Convert from base64 if it is base64
if [ "$_is_base64" = "true" ]; then
    _content=$(echo "$_content" | base64 --decode)
fi

if [ $_idx -eq 0 ]; then
    # If it's the first in the sequence
    if [ "$_final" != "true" ]; then
        # And it's not also the final one (i.e. there's more than one chunk)
        # Then create the sequence file
        touch "$_seq_file"
    fi

    # Create the parent directories if necessary
    mkdir -p -m "$_directory_permissions" "$_directory"
else
    # If it's not the first chunk
    
    # Wait for the sequence file to be created
    while [ ! -f "$_seq_file" ]; do sleep 0.05; done
    
    # Wait for the previous file to finish
    while [ "$(tail -1 "$_seq_file")" != "$(( $_idx - 1 ))" ]; do sleep 0.05; done
fi

# Store the content in the file
if [ "$_append" = "true" ]; then
    echo -n "$_content" >> "$_filename"
else
    echo -n "$_content" > "$_filename"
fi

# If it's the first in the sequence
if [ $_idx -eq 0 ]; then
    # Set permissions on the file
    chmod "$_file_permissions" "$_filename"
fi

if [ "$_final" = "true" ]; then
    # If this is the final chunk

    if [ $_idx -gt 0 ]; then
        # And there was more than one chunk
        # delete the sequence file
        rm "$_seq_file"
    fi
else
    echo "$_idx" >> $_seq_file
fi

# We must return valid JSON in order for Terraform to not lose its mind
echo -n "{}"
