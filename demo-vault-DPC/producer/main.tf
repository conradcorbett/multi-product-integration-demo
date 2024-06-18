terraform {
  cloud {
    organization = "SeeSquared"

    workspaces {
      name = "producer"
    }
  }
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.18.0"
    }
        tfe = {
      version = "~> 0.49.0"
    }
  }
}

provider "vault" {}

resource "vault_mount" "kvv2" {
  path        = "nomadsecret"
  type        = "kv"
  options     = { version = "2" }
  description = "KV Version 2 secret engine mount"
}

resource "vault_kv_secret_v2" "nomadsecret" {
  mount               = vault_mount.kvv2.path
  name                = "secret"
  cas                 = 1
  delete_all_versions = true
  data_json = jsonencode(
    {
      zip = "zap",
      foo = "bar"
    }
  )
  custom_metadata {
    max_versions = 5
    data = {
      foo = "vault@example.com",
      bar = "12345"
    }
  }
}

resource "vault_policy" "nomadjob" {
  name = "nomadjob"

  policy = <<EOT
#path "nomadsecret/data/secret/*" {
#  capabilities = ["read", "list"]
#}
path "nomadsecret/data/secret" {
  capabilities = ["read"]
}
#path "nomadsecret/metadata/secret/*" {
#  capabilities = ["read", "list"]
#}
EOT
}

data "vault_auth_backend" "tfcjwt" {
  path = "tfc/SeeSquared"
}

data "tfe_project" "project" {
  name = "hashistack"
  organization = "${var.tfc_organization}"
}

resource "vault_jwt_auth_backend_role" "nomad_role" {
  role_name = "nomad_role"
  backend   = data.vault_auth_backend.tfcjwt.path

  bound_audiences = ["vault.workload.identity"]
  user_claim      = "terraform_full_workspace"
  role_type       = "jwt"
  token_ttl       = 300
  token_policies  = [vault_policy.nomadjob.name]

  bound_claims = {
    "sub" = join(":", [
      "organization:${var.tfc_organization}",
      "project:${data.tfe_project.project.name}",
      "workspace:${tfe_workspace.consumer.name}",
      "run_phase:*",
    ])
  }

  bound_claims_type = "glob"
}

provider tfe {}

resource "tfe_workspace" "consumer" {
  name          = "consumer"
  organization  = var.tfc_organization
  project_id    = var.tfc_project_id
}

resource "tfe_variable" "tfc_vault_run_role" {
  key          = "TFC_VAULT_RUN_ROLE"
  value        = vault_jwt_auth_backend_role.nomad_role.role_name
  category     = "env"
  workspace_id = tfe_workspace.consumer.id
}
