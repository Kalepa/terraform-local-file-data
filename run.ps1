# Equivalent of set -e
$ErrorActionPreference = "Stop"

# Equivalent of set -u (https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/set-strictmode?view=powershell-7.1)
set-strictmode -version 3.0

$jsonpayload = [Console]::In.ReadLine()
$json = ConvertFrom-Json $jsonpayload

# Decode the content and filename
$_uuid = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($json.uuid))
$_idx = $json.idx
$_num_chunks = $json.num_chunks
$_content = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($json.content))
$_filename = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($json.filename))
$_is_base64 = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($json.is_base64))
$_directory = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($json.directory))
$_append = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($json.append))

# Convert from base64 if it is base64
if ( "$_is_base64" -eq "true" ) {
    $_content = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String("$_content"))
}

if ( $_num_chunks -eq 1 ) {
    # There's only one chunk, so just write directly to the destination file
    # Store the content in the file
    if ( "$_append" -eq "true" ) {
        Write-Output "$_content" | Out-File -Append -Encoding utf8 -NoNewline -FilePath "$_filename"
    }
    else {
        Write-Output "$_content" | Out-File -Encoding utf8 -NoNewline -FilePath "$_filename"
    }
}
else {
    # There are multiple chunks, so write to a temp file
    Write-Output "$_content" | Out-File -Encoding utf8 -NoNewline -FilePath "$_uuid.$_idx.chunk"

    # If it's the final chunk
    if ( $_idx -eq ( $_num_chunks - 1 ) ) {
        # Create the parent directories if necessary
        if ( !(test-path "$_directory") ) {
            New-Item -ItemType Directory -Force -Path "$_directory" | Out-Null
        }

        # Wait for each other chunk to be complete
        $_all_chunk_files = @()
        for ($i = 0; $i -lt $_num_chunks; $i += 1 ) {
            # Determine what the filename of the chunk will be
            $_chunk_file = "$_uuid.$i.chunk"

            # Wait for the file to be created
            while (!(Test-Path "$_chunk_file")) { Start-Sleep -Milliseconds 50 }

            # Add the filename to the array of filenames to cat
            $_all_chunk_files += "$_chunk_file"
        }
        
        # Merge all files into the destination file
        if ( "$_append" -eq "true" ) {
            Get-Content -Encoding utf8 -Raw $_all_chunk_files | Out-File -Append -Encoding utf8 -NoNewline -FilePath "$_filename"
        }
        else {
            Get-Content -Encoding utf8 -Raw $_all_chunk_files | Out-File -Encoding utf8 -NoNewline -FilePath "$_filename"
        }

        # Delete all chunk files
        Remove-Item $_all_chunk_files
    }
}

@{} | ConvertTo-Json
