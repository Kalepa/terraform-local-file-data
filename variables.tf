variable "file_abspath" {
  description = "The absolute path of the file to create."
  type        = string
}

variable "content" {
  description = "The content of the file to create. Conflicts with `sensitive_content` and `content_base64`."
  type        = string
  default     = null
}

variable "sensitive_content" {
  description = "The content of file to create. Will not be displayed in diffs. Conflicts with `content` and `content_base64`."
  type        = string
  default     = null
}

variable "content_base64" {
  description = "The base64 encoded content of the file to create. Use this when dealing with binary data. Conflicts with `content` and `sensitive_content`."
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
  type = bool
  default = false
}
