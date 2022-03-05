output "file_abspath" {
  depends_on = [
    data.external.create_file
  ]
  description = "The absolute path to the file that was created."
  value = var.file_abspath
}