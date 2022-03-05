# Equivalent of set -e
$ErrorActionPreference = "Stop"

# Equivalent of set -u (https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/set-strictmode?view=powershell-7.1)
set-strictmode -version 3.0

$jsonpayload = [Console]::In.ReadLine()
$json = ConvertFrom-Json $jsonpayload

# Decode the content and filename
$_content = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($json.content))
$_filename = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($json.filename))
$_is_base64 = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($json.is_base64))
$_directory = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($json.directory))
$_append = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($json.append))
  
# Convert from base64 if it is base64
if ( "$_is_base64" -eq "true" ) {
    $_content = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("$_content"))
}

# Create the parent directories if necessary
if ( !(test-path "$_directory") ) {
    New-Item -ItemType Directory -Force -Path "$_directory" | Out-Null
}

# Write the content to the file
if ( "$_append" -eq "true" ) {
    Write-Output "$_content" | Out-File -Append -Encoding utf8 -NoNewline -FilePath "$_filename"
}
else {
    Write-Output "$_content" | Out-File -Encoding utf8 -NoNewline -FilePath "$_filename"
}

@{} | ConvertTo-Json
