# Equivalent of set -e
$ErrorActionPreference = "Stop"

# Equivalent of set -u (https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/set-strictmode?view=powershell-7.1)
set-strictmode -version 3.0

$jsonpayload = [Console]::In.ReadLine()
$json = ConvertFrom-Json $jsonpayload
$_is_base64 = $json.is_base64

# Replace the magic strings with their original values
$_content = $json.content.
Replace("__76a7143569c7498988ed9f9c5748352c_TF_MAGIC_LT_STRING", "<").
Replace("__76a7143569c7498988ed9f9c5748352c_TF_MAGIC_GT_STRING", ">").
Replace("__76a7143569c7498988ed9f9c5748352c_TF_MAGIC_AMP_STRING", "&").
Replace("__76a7143569c7498988ed9f9c5748352c_TF_MAGIC_2028_STRING", "$([char]0x2028)").
Replace("__76a7143569c7498988ed9f9c5748352c_TF_MAGIC_2029_STRING", "$([char]0x2029)")

$_filename = $json.filename.
Replace("__76a7143569c7498988ed9f9c5748352c_TF_MAGIC_LT_STRING", "<").
Replace("__76a7143569c7498988ed9f9c5748352c_TF_MAGIC_GT_STRING", ">").
Replace("__76a7143569c7498988ed9f9c5748352c_TF_MAGIC_AMP_STRING", "&").
Replace("__76a7143569c7498988ed9f9c5748352c_TF_MAGIC_2028_STRING", "$([char]0x2028)").
Replace("__76a7143569c7498988ed9f9c5748352c_TF_MAGIC_2029_STRING", "$([char]0x2029)")
  
# Convert from base64 if it is base64
if ( "$_is_base64" -eq "true" ) {
    $_content = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("$_content"))
}

# Write the content to the file
Write-Output "$_content" | Out-File -NoNewline -FilePath "$_filename"

@{} | ConvertTo-Json
