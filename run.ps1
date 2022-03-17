# Equivalent of set -e
$ErrorActionPreference = "Stop"

# Equivalent of set -u (https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/set-strictmode?view=powershell-7.1)
set-strictmode -version 3.0

$jsonpayload = [Console]::In.ReadLine()
$json = ConvertFrom-Json $jsonpayload
$_filename = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($json.filename))
$_idx = $json.idx

# If the "create" variable is false, don't actually create the file, just do special actions here
if ( [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($json.create)) -ne "true" ) {
    # If we're not creating the file, but still need to update the timestamp on it, do that without writing content
    # Only if this is the first chunk though
    if ( ( $_idx -eq 0 ) -and ( [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($json.touch)) -eq "true" ) ) {
        (Get-Item "$_filename").LastWriteTime = (Get-Date)
    }
    # Exit out without doing anything else
    @{} | ConvertTo-Json
    exit 0
}

# Decode the content and filename
$_uuid = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($json.uuid))
$_num_chunks = $json.num_chunks
$_content = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($json.content))
$_is_base64 = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($json.is_base64))
$_directory = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($json.directory))
$_append = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($json.append))

# Convert from base64 if it is base64
if ( "$_is_base64" -eq "true" ) {
    $_content = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("$_content"))
}

if ( $_num_chunks -eq 1 ) {
    # There's only one chunk, so just write directly to the destination file
    # First, create the directory if necessary
    New-Item -ItemType Directory -Force -Path "$_directory" | Out-Null
    # Store the content in the file
    if ( "$_append" -eq "true" ) {
        [System.IO.File]::AppendAllText("$_filename", "$_content")
    }
    else {
        [System.IO.File]::WriteAllText("$_filename", "$_content")
    }
}
else {
    # There are multiple chunks, so write to a temp file
    [System.IO.File]::WriteAllText("$_uuid.$_idx.chunk", "$_content")

    # If it's the final chunk
    if ( $_idx -eq ( $_num_chunks - 1 ) ) {
        # Create the parent directories if necessary
        if ( !(test-path "$_directory") ) {
            New-Item -ItemType Directory -Force -Path "$_directory" | Out-Null
        }

        # Wait for each other chunk to be complete
        for ($i = 0; $i -lt $_num_chunks; $i += 1 ) {
            # Determine what the filename of the chunk will be
            $_chunk_file = "$_uuid.$i.chunk"

            # Wait for the file to be created
            while (!(Test-Path "$_chunk_file")) { Start-Sleep -Milliseconds 50 }

            # Merge all files into the destination file
            if ($i -eq 0) {
                [System.IO.File]::WriteAllText("$_filename", $(Get-Content -Encoding utf8 -Raw "$_chunk_file"))
            }
            else {
                [System.IO.File]::AppendAllText("$_filename", $(Get-Content -Encoding utf8 -Raw "$_chunk_file"))
            }
            # Delete all chunk files
            Remove-Item "$_chunk_file"
        }
    }
}

@{} | ConvertTo-Json
