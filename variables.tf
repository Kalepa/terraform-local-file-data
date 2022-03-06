variable "filename" {
  description = "The path of the file to create."
  type        = string
}

variable "content" {
  description = "The content of the file to create. Conflicts with `content_base64`."
  type        = string
  default     = null
}

variable "content_base64" {
  description = "The base64 encoded content of the file to create. Use this when dealing with binary data. Conflicts with `content`."
  type        = string
  default     = null
}

variable "file_permission" {
  description = "The permission to set for the created file. Expects a 4-character string (e.g. \"0777\"). Only has an effect when running on Unix-based systems."
  type        = string
  default     = "0777"
}

variable "directory_permission" {
  description = "The permission to set for any directories created.  Expects a 4-character string (e.g. \"0777\"). Only has an effect when running on Unix-based systems."
  type        = string
  default     = "0777"
}

variable "force_wait_for_apply" {
  description = "Whether to force this module to wait for apply-time to execute the shell command. Otherwise, it will run during plan-time if possible (i.e. if all inputs are known during plan time)."
  type        = bool
  default     = false
}

variable "append" {
  description = "Whether to append to the file instead of overwriting it. CAUTION: this will append to the file on each plan (or apply, if `force_wait_for_apply` is set to `true), so the file may grow VERY LARGE."
  type        = bool
  default     = false
}

variable "max_characters" {
  description = <<EOF
The maximum number of characters that the file will contain. This is only to be used when the size of the file exceeds 4MB, which is the maximum size that various Terraform plugins can support.

If this value is set, this module will split the file contents into pieces that are smaller than the limit and only send one chunk at a time. If this value is not set, it will assume that the file is smaller than the 4MB limit.
EOF
  type        = number
  default     = null
}

variable "override_chunk_size" {
  description = "Set this variable to override the default per-file chunk size. This is generally only used for testing and should not normally be used. If you do set it, ensure that you set it to a value that is a multiple of 76 so that it doesn't break base64 encoding where it splits."
  type        = number
  // We're limited to 4MB, which is about 3,000,000 bytes before the 36% base64 overhead.
  // With Terraform's UTF-8 encoding, there could be upt to 4 bytes per character, so 3,000,000/4 = 749,968 characters max.
  // To be able to handle base64 encoding and not break it when splitting, we use the nearest multiple of 76, since the
  // base64 specs use line lengths of 76 characters
  default = 749968
}
