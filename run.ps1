# Equivalent of set -e
$ErrorActionPreference = "Stop"

# Equivalent of set -u (https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/set-strictmode?view=powershell-7.1)
set-strictmode -version 3.0

$jsonpayload = [Console]::In.ReadLine()
$json = ConvertFrom-Json $jsonpayload

# Decode the content and filename
$_uuid = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($json.uuid))
$_idx = $json.idx
$_final = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($json.final))
$_tmp_dir = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($json.temp_dir))
$_content = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($json.content))
$_filename = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($json.filename))
$_is_base64 = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($json.is_base64))
$_directory = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($json.directory))
$_append = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($json.append))

$_seq_file = "$_tmp_dir/$_uuid.seq"

# Convert from base64 if it is base64
if ( "$_is_base64" -eq "true" ) {
    $_content = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("$_content"))
}

if ( $_idx -eq 0 ) {
    # If it's the first in the sequence
    if ("$_final" -ne "true" ) {
        # And it's not also the final one (i.e. there's more than one chunk)
        # Then create the sequence file
        New-Item -Path "$_seq_file" -type File | Out-Null
    }
    # Create the parent directories if necessary
    if ( !(test-path "$_directory") ) {
        New-Item -ItemType Directory -Force -Path "$_directory" | Out-Null
    }
}
else {
    # If it's not the first chunk
    
    # Wait for the sequence file to be created
    while (!(Test-Path "$_seq_file")) { Start-Sleep -Milliseconds 50 }

    # Wait for the previous file to finish
    while (1) {
        $_last_line = Get-Content "$_seq_file" -tail 1
        if ($_last_line -eq ($_idx - 1).ToString()) {
            break
        }
        Start-Sleep -Milliseconds 50
    }
}

# Write the content to the file
if ( "$_append" -eq "true" ) {
    Write-Output "$_content" | Out-File -Append -Encoding utf8 -NoNewline -FilePath "$_filename"
}
else {
    Write-Output "$_content" | Out-File -Encoding utf8 -NoNewline -FilePath "$_filename"
}

if ( "$_final" -eq "true"  ) {
    # If this is the final chunk
    if ($_idx -gt 0) {
        # And there was more than one chunk
        # delete the sequence file
        Remove-Item "$_seq_file"
    }
}
else {
    # Otherwise, write the completed sequence number to the file
    Write-Output "$_idx" | Out-File -Append -Encoding utf8 -FilePath "$_seq_file"
}

@{} | ConvertTo-Json
