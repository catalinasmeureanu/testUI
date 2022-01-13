#!/bin/bash -x
set -aex

# start vault dev server
vault server -dev -dev-root-token-id="root"&

sleep 2

export VAULT_ADDR='http://127.0.0.1:8200'

vault login root

#create kv version 2 secret engine

vault secrets enable -version=2 kv
vault kv put kv/my-secret foo=a bar=b
vault kv get kv/my-secret

vault kv put secret/my-secret foo=aa bar=bb
vault kv get secret/my-secret

# create admin policy that doesn't have access to read secrets from path kv

cat > admin-policy.hcl <<EOF
# Read system health check
path "sys/health"
{
  capabilities = ["read", "sudo"]
}

# Create and manage ACL policies broadly across Vault

# List existing policies
path "sys/policies/acl"
{
  capabilities = ["list"]
}

# Create and manage ACL policies
path "sys/policies/acl/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Enable and manage authentication methods broadly across Vault

# Manage auth methods broadly across Vault
path "auth/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Create, update, and delete auth methods
path "sys/auth/*"
{
  capabilities = ["create", "update", "delete", "sudo"]
}

# List auth methods
path "sys/auth"
{
  capabilities = ["read"]
}

# Enable and manage the key/value secrets engine at  path

# List, create, update, and delete key/value secrets
path "secret/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# List, create, update, and delete key/value secrets
path "kv/*"
{
  capabilities = ["sudo"]
}

# Manage secrets engines
path "sys/mounts/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# List existing secrets engines.
path "sys/mounts"
{
  capabilities = ["read"]
}
EOF

vault policy write admin admin-policy.hcl

# create a token with admin policy
vault token create -policy=admin