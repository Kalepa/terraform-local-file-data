# Terraform Local File (Data)

This module functions similarly to the [local_file](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) resource, but acts as a data source instead of a resource.

Specifically, it will *always* create or overwrite the specified file, regardless of whether the content has changed. It does not track the state of the file.

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
