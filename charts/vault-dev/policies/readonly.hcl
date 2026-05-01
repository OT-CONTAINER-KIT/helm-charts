# Read-only policy across all secrets
path "secret/*" {
  capabilities = ["read", "list"]
}
