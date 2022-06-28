//==================================================
//     Outputs that match the input variables
//==================================================
output "dynamic_depends_on" {
  description = "The value of the `dynamic_depends_on` input variable."
  value       = local.var_dynamic_depends_on
}
output "filename" {
  description = "The value of the `filename` input variable."
  value       = local.var_filename
}
output "content" {
  description = "The value of the `content` input variable."
  value       = local.var_content
}
output "content_base64" {
  description = "The value of the `content_base64` input variable."
  value       = local.var_content_base64
}
output "file_permission" {
  description = "The value of the `file_permission` input variable, or the default value if the input was `null`."
  value       = local.var_file_permission
}
output "directory_permission" {
  description = "The value of the `directory_permission` input variable, or the default value if the input was `null`."
  value       = local.var_directory_permission
}
output "force_wait_for_apply" {
  description = "The value of the `force_wait_for_apply` input variable, or the default value if the input was `null`."
  value       = local.var_force_wait_for_apply
}
output "append" {
  description = "The value of the `append` input variable, or the default value if the input was `null`."
  value       = local.var_append
}
output "max_characters" {
  description = "The value of the `max_characters` input variable."
  value       = local.var_max_characters
}
output "force_update_last_modified" {
  description = "The value of the `force_update_last_modified` input variable, or the default value if the input was `null`."
  value       = local.var_force_update_last_modified
}
output "chunk_size" {
  description = "The value of the `chunk_size` input variable, or the default value if the input was `null`."
  value       = local.var_chunk_size
}
output "unix_interpreter" {
  description = "The value of the `unix_interpreter` input variable, or the default value if the input was `null`."
  value       = local.var_unix_interpreter
}

//==================================================
//       Outputs generated by this module
//==================================================
output "complete" {
  description = "Always `true`, but does not return until the file has been created."
  value       = jsonencode(values(data.external.create_file_chunk)) == "" ? true : true
}

output "num_chunks" {
  description = "The number of chunks that the file was split into during the writing process (this output is only useful for debugging)."
  value       = local.num_chunks
}

output "modified" {
  description = "Whether the file had been (or, if the file can't be created until apply-time, must be) modified. Will be `true` if the file doesn't already exist or if the contents have changed, and `false` otherwise."
  value       = local.needs_creation
}
