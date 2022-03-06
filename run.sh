#!/bin/bash

set -eu

# We know that all of the inputs are base64-encoded, and "|" is not a valid base64 character, so therefore it
# cannot possibly be included in the stdin.
IFS="|" read -a PARAMS <<< $(cat | sed -e 's/__76a7143569c7498988ed9f9c5748352c_TF_MAGIC_SEGMENT_SEPARATOR/|/g')

_create=$(echo "${PARAMS[1]}" | base64 --decode)
_touch=$(echo "${PARAMS[2]}" | base64 --decode)
_uuid=$(echo "${PARAMS[3]}" | base64 --decode)
_idx="${PARAMS[4]}"
_num_chunks="${PARAMS[5]}"
_content=$(echo "${PARAMS[6]}" | base64 --decode)
_filename=$(echo "${PARAMS[7]}" | base64 --decode)
_is_base64=$(echo "${PARAMS[8]}" | base64 --decode)
_file_permissions=$(echo "${PARAMS[9]}" | base64 --decode)
_directory_permissions=$(echo "${PARAMS[10]}" | base64 --decode)
_directory=$(echo "${PARAMS[11]}" | base64 --decode)
_append=$(echo "${PARAMS[12]}" | base64 --decode)

# If the "create" variable is false, don't actually create the file, just do special actions here
if [ "$_create" != "true" ]; then
    # If we're not creating the file, but still need to update the timestamp on it, do that without writing content
    # Only if this is the first chunk though
    if [ $_idx -eq 0 ]; then
        if [ "$_touch" = "true" ]; then
            touch "$_filename"
        fi
        # Set permissions on the file
        chmod "$_file_permissions" "$_filename"
    fi
    # Exit out without doing anything else
    echo -n "{}"
    exit 0
fi

# Convert from base64 if it is base64
if [ "$_is_base64" = "true" ]; then
    _content=$(echo "$_content" | base64 --decode)
fi

if [ $_num_chunks -eq 1 ]; then
    # There's only one chunk, so just write directly to the destination file
    # Store the content in the file
    if [ "$_append" = "true" ]; then
        echo -n "$_content" >> "$_filename"
    else
        echo -n "$_content" > "$_filename"
    fi
else
    # There are multiple chunks, so write to a temp file
    echo -n "$_content" > "$_uuid.$_idx.chunk"

    # If it's the final chunk
    if [ $_idx -eq $(( $_num_chunks - 1 )) ]; then
        # Create the parent directories if necessary
        mkdir -p -m "$_directory_permissions" "$_directory"

        # Wait for each other chunk to be complete
        _all_chunk_files=()
        for (( i=0; i<$_num_chunks; i++)); do
            # Determine what the filename of the chunk will be
            _chunk_file="$_uuid.$i.chunk"

            # Wait for the file to be created
            while [ ! -f "$_chunk_file" ]; do sleep 0.05; done
            
            # Add the filename to the array of filenames to cat
            _all_chunk_files+=("$_chunk_file")
        done

        # Merge all files into the destination file
        if [ "$_append" = "true" ]; then
            cat "${_all_chunk_files[@]}" >> "$_filename"
        else
            cat "${_all_chunk_files[@]}" > "$_filename"
        fi

        # Set permissions on the file
        chmod "$_file_permissions" "$_filename"

        # Delete all chunk files
        rm ${_all_chunk_files[@]}
    fi  
fi

# We must return valid JSON in order for Terraform to not lose its mind
echo -n "{}"
