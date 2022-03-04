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
  content   = var.content != null && var.content != "" ? var.content : (var.sensitive_content != null && var.sensitive_content != "" ? sensitive(var.sensitive_content) : var.content_base64)
  is_base64 = (var.content == null || var.content == "") && (var.sensitive_content == null || var.sensitive_content == "") && var.content_base64 != null && var.content_base64 != ""

  content_special_jsonencode_replaced = replace(replace(replace(replace(replace(local.content,
    "<", "__76a7143569c7498988ed9f9c5748352c_TF_MAGIC_LT_STRING"),
    ">", "__76a7143569c7498988ed9f9c5748352c_TF_MAGIC_GT_STRING"),
    "&", "__76a7143569c7498988ed9f9c5748352c_TF_MAGIC_AMP_STRING"),
    "\u2028", "__76a7143569c7498988ed9f9c5748352c_TF_MAGIC_2028_STRING"),
    "\u2029", "__76a7143569c7498988ed9f9c5748352c_TF_MAGIC_2029_STRING"
  )
  filename_special_jsonencode_replaced = replace(replace(replace(replace(replace(var.filename,
    "<", "__76a7143569c7498988ed9f9c5748352c_TF_MAGIC_LT_STRING"),
    ">", "__76a7143569c7498988ed9f9c5748352c_TF_MAGIC_GT_STRING"),
    "&", "__76a7143569c7498988ed9f9c5748352c_TF_MAGIC_AMP_STRING"),
    "\u2028", "__76a7143569c7498988ed9f9c5748352c_TF_MAGIC_2028_STRING"),
    "\u2029", "__76a7143569c7498988ed9f9c5748352c_TF_MAGIC_2029_STRING"
  )
  query = local.is_windows ? {
    // If it's Windows, just use the input value since PowerShell can natively handle JSON decoding
    content   = local.content_special_jsonencode_replaced
    filename  = local.filename_special_jsonencode_replaced
    is_base64 = local.is_base64
    } : {
    // If it's Unix, we have to convert all characters that JSON escapes into special strings that we can easily convert back WITHOUT needing any other installed tools such as jq
    "" = join("", [local.unix_query_separator, join(local.unix_query_separator, [
      replace(replace(replace(replace(replace(local.content_special_jsonencode_replaced,
        "\n", "__76a7143569c7498988ed9f9c5748352c_TF_MAGIC_NL_STRING"),
        "\r", "__76a7143569c7498988ed9f9c5748352c_TF_MAGIC_CR_STRING"),
        "\t", "__76a7143569c7498988ed9f9c5748352c_TF_MAGIC_TAB_STRING"),
        "\"", "__76a7143569c7498988ed9f9c5748352c_TF_MAGIC_DQ_STRING"),
        "\\", "__76a7143569c7498988ed9f9c5748352c_TF_MAGIC_BS_STRING"
      ),
      local.filename_special_jsonencode_replaced,
      local.is_base64 ? "true" : "false"
    ]), local.unix_query_separator])
  }
}

data "external" "run" {
  program = local.is_windows ? ["powershell.exe", "${abspath(path.module)}/run.ps1"] : ["${abspath(path.module)}/run.sh"]
  query   = local.query
  // Force the data source to wait for the assertion to complete AND, if desired, for apply
  working_dir = module.assert_valid_input.checked && local.wait_for_apply == null ? path.module : path.module
}
