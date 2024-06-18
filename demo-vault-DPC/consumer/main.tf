terraform {
  cloud {
    organization = "SeeSquared"

    workspaces {
      name = "consumer"
    }
  }
  required_providers {

    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.18.0"
    }

    nomad = {
      source  = "hashicorp/nomad"
      version = "2.0.0-beta.1"
    }
  }
}

provider "vault" {}

data "vault_kv_secret_v2" "nomadsecret" {
  mount = "nomadsecret"
  name  = "secret"
}

output "nomadsecretfoo" {
  value = nonsensitive(data.vault_kv_secret_v2.nomadsecret.data["foo"])
}

output "nomadsecret" {
  value = nonsensitive(data.vault_kv_secret_v2.nomadsecret.data)
}