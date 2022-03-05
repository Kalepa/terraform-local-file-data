terraform {
  required_version = ">= 0.13.0"
}

module "assert_valid_input" {
  source  = "Invicton-Labs/assertion/null"
  version = "~>0.2.1"
  condition = length(compact([for c in [
    var.content,
    var.sensitive_content,
    var.content_base64
    ] :
    c == null ? "" : c
  ])) == 1
  error_message = "Exactly one of `content`, `sensitive_content`, or `content_base64` must be provided."
}

locals {
  is_windows = dirname("/") == "\\"
  // We use the uuid function to force a wait for apply, since Terraform doesn't generate the UUID until the apply step
  wait_for_apply = var.force_wait_for_apply ? uuid() : null

  unix_query_separator = "__76a7143569c7498988ed9f9c5748352c_TF_MAGIC_SEGMENT_SEPARATOR"

  // Find the correct content source
  content   = module.assert_valid_input.checked ? var.content != null && var.content != "" ? var.content : (var.sensitive_content != null && var.sensitive_content != "" ? sensitive(var.sensitive_content) : var.content_base64) : null
  is_base64 = (var.content == null || var.content == "") && (var.sensitive_content == null || var.sensitive_content == "") && var.content_base64 != null && var.content_base64 != ""

  query = local.is_windows ? {
    // If it's Windows, just use the input value since PowerShell can natively handle JSON decoding
    content   = base64encode(local.content)
    filename  = base64encode(var.file_abspath)
    is_base64 = base64encode(local.is_base64 ? "true" : "false")
    directory = base64encode(dirname(var.file_abspath))
    append    = base64encode(var.append ? "true" : "false")
    } : {
    // If it's Unix, we have to convert all characters that JSON escapes into special strings that we can easily convert back WITHOUT needing any other installed tools such as jq
    "" = join("", [local.unix_query_separator, join(local.unix_query_separator, [
      base64encode(local.content),
      base64encode(var.file_abspath),
      base64encode(local.is_base64 ? "true" : "false"),
      base64encode(var.file_permission),
      base64encode(var.directory_permission),
      base64encode(dirname(var.file_abspath)),
      base64encode(var.append ? "true" : "false")
    ]), local.unix_query_separator])
  }
}

data "external" "run" {
  program = local.is_windows ? ["powershell.exe", "${abspath(path.module)}/run.ps1"] : ["${abspath(path.module)}/run.sh"]
  query   = local.query
  // Force the data source to wait for the assertion to complete AND, if desired, for apply
  working_dir = module.assert_valid_input.checked && local.wait_for_apply == null ? path.module : path.module
}
