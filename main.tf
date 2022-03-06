// Check that the correct content inputs are provided
module "assert_valid_input" {
  source  = "Invicton-Labs/assertion/null"
  version = "~>0.2.1"
  condition = length([for c in [
    var.content,
    var.content_base64
    ] :
    true
    if c != null
  ]) == 1
  error_message = "Exactly one of `content` or `content_base64` must be provided."
}

// Check that the file is within the single-chunk size limits unless the user has made it clear that
// they want it to be multi-chunk.
module "assert_chunked" {
  source        = "Invicton-Labs/assertion/null"
  version       = "~>0.2.1"
  condition     = length(local.content) <= var.override_chunk_size || var.max_characters != null
  error_message = "If the content length is greater than the file chunk size (${var.override_chunk_size} characters), then the `max_characters` variable must be provided and known during the plan step."
}

// Create a UUID for this run of this module (changes on every plan step)
module "uuid" {
  source  = "Invicton-Labs/uuid/null"
  version = "~>0.1.0"
}

locals {
  is_windows = dirname("/") == "\\"

  // A magic string that we use as a separator. It contains a UUID, so in theory, should
  // be a globally unique ID that will never appear in input content
  unix_query_separator = "__76a7143569c7498988ed9f9c5748352c_TF_MAGIC_SEGMENT_SEPARATOR"

  // Whether the content came from the content_base64 variable
  is_base64 = var.content == null

  // Find the correct content source
  content = module.assert_valid_input.checked ? (local.is_base64 ? var.content_base64 : var.content) : null

  // Whether the output file already exists
  file_exists = fileexists(var.filename)

  // Try decoding the content if it's base64
  content_decoded = local.file_exists && local.is_base64 ? try(base64decode(local.content), null) : null

  // Ensure that the content we're reviewing is the "most raw" we can get it
  // Only compute this if the file already exists and we need to compare content, to save memory if not
  content_raw = local.file_exists ? (local.content_decoded == null ? local.content : local.content_decoded) : null

  // Get the length of the content
  // Only compute this if the file already exists and we need to compare content, to save memory if not
  content_raw_length = local.file_exists ? length(local.content_raw) : null

  // The full content except for the last character
  // Only compute this if the file already exists and we need to compare content, to save memory if not
  content_raw_except_last = local.file_exists ? (local.content_raw_length == 0 ? "" : substr(local.content_raw, 0, local.content_raw_length - 1)) : null

  // The various hashes that we'll accept as "equal" to the existing file
  possible_hashes = local.file_exists ? concat(
    [
      // The hash of the full content is OK
      base64sha256(local.content)
    ],
    // Terraform does weird things with CRLF, see https://github.com/hashicorp/terraform/issues/30619
    // So, if the final character is a CRLF, CR, or LF, we allow matching on different line endings
    // for this ONE CHARACTER, it's the only one that's allowed to be slightly different.
    local.content_raw_length > 0 && contains(["\r\n", "\r", "\n"], substr(local.content_raw, -1, -1)) ? [
      // If we decoded the base64 to get the raw content, then re-encode it before taking the hash
      base64sha256(local.content_decoded == null ? join("", [local.content_raw_except_last, "\r"]) : base64encode(join("", [local.content_raw_except_last, "\r"]))),
      base64sha256(local.content_decoded == null ? join("", [local.content_raw_except_last, "\n"]) : base64encode(join("", [local.content_raw_except_last, "\n"]))),
    ] : []
  ) : null

  // If the input is base64, then we want to compare against the base64-encoded file for apples-to-apples comparison
  file_hash = local.file_exists ? (local.is_base64 ? base64sha256(filebase64(var.filename)) : filebase64sha256(var.filename)) : null

  // Whether or not the file needs to be created. Could be that it was never created before, or
  // that it has been deleted, or that the content has changed.
  needs_creation = local.file_exists ? !contains(local.possible_hashes, local.file_hash) : true

  // Calculate how many chunks we need to split it into
  num_chunks = var.max_characters == null ? 1 : ceil(var.max_characters / var.override_chunk_size)

  // Split it into chunks
  chunks = local.num_chunks == 1 ? {
    0 = local.needs_creation ? base64encode(local.content) : ""
    } : {
    for i in range(0, local.num_chunks) :
    i => local.needs_creation ? base64encode(substr(local.content, i * var.override_chunk_size, var.override_chunk_size)) : ""
  }

  create_base64               = base64encode(local.needs_creation ? "true" : "false")
  touch_base64                = base64encode(var.force_update_last_modified ? "true" : "false")
  filename_base64             = base64encode(abspath(var.filename))
  uuid_base64                 = base64encode(module.uuid.uuid)
  is_base64_base64            = base64encode(local.is_base64 ? "true" : "false")
  file_permission_base64      = base64encode(var.file_permission)
  directory_permission_base64 = base64encode(var.directory_permission)
  dirname_base64              = base64encode(dirname(abspath(var.filename)))
  append_base64               = base64encode(var.append ? "true" : "false")

  // We use the uuid function to force a wait for apply, since Terraform doesn't generate the UUID until the apply step
  // Only wait if the file needs to be created AND the associated variable is set
  wait_for_apply = local.needs_creation ? (var.force_wait_for_apply ? uuid() : null) : null
}

data "external" "create_file_chunk" {
  program  = local.is_windows ? ["powershell.exe", "${abspath(path.module)}/run.ps1"] : ["${abspath(path.module)}/run.sh"]
  for_each = local.chunks
  query = sensitive(local.is_windows ? {
    // If it's Windows, just use the input value since PowerShell can natively handle JSON decoding
    create     = local.create_base64
    touch      = local.touch_base64
    uuid       = local.uuid_base64
    idx        = tonumber(each.key)
    num_chunks = local.num_chunks
    content    = each.value
    filename   = local.filename_base64
    is_base64  = local.is_base64_base64
    directory  = local.dirname_base64
    append     = local.append_base64
    } : {
    // If it's Unix, we have to convert all characters that JSON escapes into special strings that we can easily convert back WITHOUT needing any other installed tools such as jq
    "" = join("", [local.unix_query_separator, join(local.unix_query_separator, [
      local.create_base64,
      local.touch_base64,
      local.uuid_base64,
      tonumber(each.key),
      local.num_chunks,
      each.value,
      local.filename_base64,
      local.is_base64_base64,
      local.file_permission_base64,
      local.directory_permission_base64,
      local.dirname_base64,
      local.append_base64,
    ]), local.unix_query_separator])
  })
  // Force the data source to wait for the apply, if that is what is desired
  working_dir = module.assert_chunked.checked && local.wait_for_apply == null ? "${path.module}/tmpfiles" : "${path.module}/tmpfiles"
}
