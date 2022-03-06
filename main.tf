terraform {
  required_version = ">= 0.13.0"
}

module "assert_valid_input" {
  source  = "Invicton-Labs/assertion/null"
  version = "~>0.2.1"
  condition = length(compact([for c in [
    var.content,
    var.content_base64
    ] :
    c == null ? "" : "dummy"
  ])) == 1
  error_message = "Exactly one of `content` or `content_base64` must be provided."
}

module "uuid" {
  source  = "Invicton-Labs/uuid/null"
  version = "~>0.1.0"
}

locals {
  is_windows = dirname("/") == "\\"
  // We use the uuid function to force a wait for apply, since Terraform doesn't generate the UUID until the apply step
  wait_for_apply = var.force_wait_for_apply ? uuid() : null

  // A magic string that we use as a separator. It contains a UUID, so in theory, should
  // be a globally unique ID that will never appear in input content
  unix_query_separator = "__76a7143569c7498988ed9f9c5748352c_TF_MAGIC_SEGMENT_SEPARATOR"

  // Find the correct content source
  content = module.assert_valid_input.checked ? (var.content != null ? var.content : var.content_base64) : null

  // Whether the content came from the content_base64 variable
  is_base64 = var.content == null

  // Calculate how many chunks we need to split it into
  num_chunks = var.max_characters == null ? 1 : ceil(var.max_characters / var.override_chunk_size)

  // Split it into chunks
  chunks = local.num_chunks == 1 ? { 0 = base64encode(local.content) } : {
    for i in range(0, local.num_chunks) :
    i => base64encode(substr(local.content, i * var.override_chunk_size, var.override_chunk_size))
  }

  uuid_base64                 = base64encode(module.uuid.uuid)
  file_abspath_base64         = base64encode(var.file_abspath)
  is_base64_base64            = base64encode(local.is_base64 ? "true" : "false")
  file_permission_base64      = base64encode(var.file_permission)
  directory_permission_base64 = base64encode(var.directory_permission)
  dirname_base64              = base64encode(dirname(var.file_abspath))
  append_base64               = base64encode(var.append ? "true" : "false")
}

data "external" "create_file" {
  program  = local.is_windows ? ["powershell.exe", "${abspath(path.module)}/run.ps1"] : ["${abspath(path.module)}/run.sh"]
  for_each = local.chunks
  query = sensitive(local.is_windows ? {
    // If it's Windows, just use the input value since PowerShell can natively handle JSON decoding
    uuid       = local.uuid_base64
    idx        = tonumber(each.key)
    num_chunks = local.num_chunks
    content    = each.value
    filename   = local.file_abspath_base64
    is_base64  = local.is_base64_base64
    directory  = local.dirname_base64
    append     = local.append_base64
    } : {
    // If it's Unix, we have to convert all characters that JSON escapes into special strings that we can easily convert back WITHOUT needing any other installed tools such as jq
    "" = join("", [local.unix_query_separator, join(local.unix_query_separator, [
      local.uuid_base64,
      tonumber(each.key),
      local.num_chunks,
      each.value,
      local.file_abspath_base64,
      local.is_base64_base64,
      local.file_permission_base64,
      local.directory_permission_base64,
      local.dirname_base64,
      local.append_base64,
    ]), local.unix_query_separator])
  })
  // Force the data source to wait for the assertion to complete AND, if desired, for apply
  working_dir = module.assert_valid_input.checked && local.wait_for_apply == null ? "${path.module}/tmpfiles" : "${path.module}/tmpfiles"
}
