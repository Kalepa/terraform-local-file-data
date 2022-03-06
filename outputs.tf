output "filename" {
  depends_on = [
    data.external.create_file_chunk
  ]
  description = "The path to the file that was created. Does not return until the file has been created."
  value       = var.filename
}

output "complete" {
  depends_on = [
    data.external.create_file_chunk
  ]
  description = "Always `true`, but does not return until the file has been created."
  value       = true
}

output "num_chunks" {
  description = "The number of chunks that the file was split into during the writing process (this output is only useful for debugging)."
  value       = local.num_chunks
}

output "default_chunk_size" {
  description = "The default number of characters in each chunk."
  value       = local.default_chunk_size
}

output "must_be_modified" {
  description = "Whether the file must be modified. Will be `true` if the file doesn't already exist or if the contents have changed, and `false` otherwise."
  value       = local.needs_creation
}
