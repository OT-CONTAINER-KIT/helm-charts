# Admin policy granting full access
path "*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
