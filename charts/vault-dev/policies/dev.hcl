# Developer policy for read/write on specific secrets
path "secret/data/dev/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
