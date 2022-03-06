# Terraform Local File (Data)

This module functions similarly to the [local_file](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) resource, but acts as a data source instead of a resource.

Specifically, it will *always* create or overwrite the specified file, regardless of whether the content has changed.

This module also optionally supports "large" files. The `local_file` resource has a hard limit of 4MB; if you want to create files larger than 4MB, you can use the `max_characters` variable of this module to enable support for files with no size limits.

This module has been tested on Linux and Windows, but not MacOS. In theory, it should function on any Unix-based OS that supports `bash` and `base64` commands, or any Windows-based OS that supports PowerShell.

## Limitations

- The `file_permission` and `directory_permission` variables have no effect when running on Windows, as PowerShell has no `chmod` equivalent.

## Usage

```
module "local-file-data" {
  source = "Invicton-Labs/file-data/local"

  // ALWAYS use the absolute path. It cannot handle relative paths, since they 
  // will be relative to the inner module instead of the calling module.
  file_abspath = abspath("${path.module}/testdir/test.txt")

  content = "Hello World!
}
```
