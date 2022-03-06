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

  // The directory where temporary files should be stored
  temporary_dir = abspath("${path.module}/tmpfiles")

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
  chunks = local.num_chunks == 1 ? { 0 = local.content } : {
    for i in range(0, local.num_chunks) :
    i => substr(local.content, i * var.override_chunk_size, var.override_chunk_size)
  }
}

data "external" "create_file" {
  program  = local.is_windows ? ["powershell.exe", "${abspath(path.module)}/run.ps1"] : ["${abspath(path.module)}/run.sh"]
  for_each = local.chunks
  query = sensitive(local.is_windows ? {
    // If it's Windows, just use the input value since PowerShell can natively handle JSON decoding
    uuid      = base64encode(module.uuid.uuid)
    idx       = tonumber(each.key)
    final     = base64encode(tonumber(each.key) == local.num_chunks - 1 ? "true" : "false")
    temp_dir  = base64encode(local.temporary_dir)
    content   = base64encode(each.value)
    filename  = base64encode(var.file_abspath)
    is_base64 = base64encode(local.is_base64 ? "true" : "false")
    directory = base64encode(dirname(var.file_abspath))
    append    = base64encode(var.append || tonumber(each.key) > 0 ? "true" : "false")
    } : {
    // If it's Unix, we have to convert all characters that JSON escapes into special strings that we can easily convert back WITHOUT needing any other installed tools such as jq
    "" = join("", [local.unix_query_separator, join(local.unix_query_separator, [
      base64encode(module.uuid.uuid),
      tonumber(each.key),
      base64encode(tonumber(each.key) == local.num_chunks - 1 ? "true" : "false"),
      base64encode(local.temporary_dir),
      base64encode(each.value),
      base64encode(var.file_abspath),
      base64encode(local.is_base64 ? "true" : "false"),
      base64encode(var.file_permission),
      base64encode(var.directory_permission),
      base64encode(dirname(var.file_abspath)),
      base64encode(var.append || tonumber(each.key) > 0 ? "true" : "false")
    ]), local.unix_query_separator])
  })
  // Force the data source to wait for the assertion to complete AND, if desired, for apply
  working_dir = module.assert_valid_input.checked && local.wait_for_apply == null ? path.module : path.module
}
