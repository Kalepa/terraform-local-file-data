#!/bin/bash

set -eu

# We know that we replaced the ">" character with a magic string in Terraform, so it can't possibly appear in
# the stdin. Therefore, we can safely use it as a separator to split the different input segments.
IFS=">" read -a PARAMS <<< $(cat | sed -e 's/__76a7143569c7498988ed9f9c5748352c_TF_MAGIC_SEGMENT_SEPARATOR/>/g')

function func_unescape {
    echo -n "$1" | sed \
        -e 's/__76a7143569c7498988ed9f9c5748352c_TF_MAGIC_LT_STRING/</g' \
        -e 's/__76a7143569c7498988ed9f9c5748352c_TF_MAGIC_GT_STRING/>/g' \
        -e 's/__76a7143569c7498988ed9f9c5748352c_TF_MAGIC_AMP_STRING/</g' \
        -e 's/__76a7143569c7498988ed9f9c5748352c_TF_MAGIC_2028_STRING/\u2028/g' \
        -e 's/__76a7143569c7498988ed9f9c5748352c_TF_MAGIC_2029_STRING/\u2029/g' \
        -e 's/__76a7143569c7498988ed9f9c5748352c_TF_MAGIC_NL_STRING/\n/g' \
        -e 's/__76a7143569c7498988ed9f9c5748352c_TF_MAGIC_CR_STRING/\r/g' \
        -e 's/__76a7143569c7498988ed9f9c5748352c_TF_MAGIC_TAB_STRING/\t/g' \
        -e 's/__76a7143569c7498988ed9f9c5748352c_TF_MAGIC_DQ_STRING/"/g' \
        -e 's/__76a7143569c7498988ed9f9c5748352c_TF_MAGIC_BS_STRING/\\/g'
}

_content=$(func_unescape "${PARAMS[1]}")
_filename=$(func_unescape "${PARAMS[2]}")
_is_base64="${PARAMS[3]}"

if [ "$_is_base64" = "true" ]; then
    _content=$(echo "$_content" | base64 --decode)
fi

# Store the content in the file
echo -n "$_content" > "$_filename"

# We must return valid JSON in order for Terraform to not lose its mind
echo -n "{}"
