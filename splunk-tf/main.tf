terraform {
  required_providers {
    terracurl = {
      source  = "devops-rob/terracurl"
      version = "1.0.1"
    }    
    doormat = {
      source  = "doormat.hashicorp.services/hashicorp-security/doormat"
      version = "~> 0.0.6"
    }

    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.8.0"
    }

    vault = {
      source = "hashicorp/vault"
      version = "~> 3.18.0"
    }

    nomad = {
      source = "hashicorp/nomad"
      version = "2.0.0-beta.1"
    }

    consul = {
      source = "hashicorp/consul"
      version = "2.18.0"
    }
  }
}

provider "doormat" {}

provider "consul" {
  address = "${data.terraform_remote_state.hcp_clusters.outputs.consul_public_endpoint}:443"
  token = data.terraform_remote_state.hcp_clusters.outputs.consul_root_token
  scheme  = "https" 
}
 
data "doormat_aws_credentials" "creds" {
  provider = doormat
  role_arn = "arn:aws:iam::${var.aws_account_id}:role/tfc-doormat-role_9_splunk-tf"
}

provider "aws" {
  region     = var.region
  access_key = data.doormat_aws_credentials.creds.access_key
  secret_key = data.doormat_aws_credentials.creds.secret_key
  token      = data.doormat_aws_credentials.creds.token
}

data "terraform_remote_state" "networking" {
  backend = "remote"

  config = {
    organization = var.tfc_organization
    workspaces = {
      name = "1_networking"
    }
  }
}

data "terraform_remote_state" "hcp_clusters" {
  backend = "remote"

  config = {
    organization = var.tfc_organization
    workspaces = {
      name = "2_hcp-clusters"
    }
  }
}

data "terraform_remote_state" "nomad_cluster" {
  backend = "remote"

  config = {
    organization = var.tfc_organization
    workspaces = {
      name = "5_nomad-cluster"
    }
  }
}

data "terraform_remote_state" "nomad_nodes" {
  backend = "remote"

  config = {
    organization = var.tfc_organization
    workspaces = {
      name = "6_nomad-nodes"
    }
  }
}

provider "vault" {}

data "vault_kv_secret_v2" "bootstrap" {
  mount = data.terraform_remote_state.nomad_cluster.outputs.bootstrap_kv
  name  = "nomad_bootstrap/SecretID"
}

provider "nomad" {
  address = data.terraform_remote_state.nomad_cluster.outputs.nomad_public_endpoint
  secret_id = data.vault_kv_secret_v2.bootstrap.data["SecretID"]
}

data "vault_kv_secret_v2" "vault-dev-root-token" {
  mount = data.terraform_remote_state.nomad_cluster.outputs.bootstrap_kv
  name  = "vault_token"
}

resource "nomad_job" "demo-vault" {
  hcl2 {
    vars = {
       myvaulttoken = data.vault_kv_secret_v2.vault-dev-root-token.data["VAULT_ROOT_TOKEN"]
    }
  }
  jobspec = file("${path.module}/nomad-jobs/1-demo-vault.nomad.hcl")
}

resource "time_sleep" "wait_15_seconds_1" {
  depends_on = [nomad_job.demo-vault]
  create_duration = "15s"
}

data "aws_instance" "nomad_x86_client" {
  instance_tags = {
    "aws:autoscaling:groupName" = "nomad-client-x86"
  }
  filter {
    name = "instance-state-name"
    values = ["running"]
  }
}

resource "nomad_job" "demo-splunk" {
  depends_on = [time_sleep.wait_15_seconds_1]
  jobspec = file("${path.module}/nomad-jobs/2-demo-splunkv2.nomad.hcl")
}

resource "time_sleep" "wait_15_seconds_2" {
  depends_on = [nomad_job.demo-splunk]
  create_duration = "15s"
}

resource "nomad_job" "demo-fluentd" {
  depends_on = [time_sleep.wait_15_seconds_2]
  jobspec = file("${path.module}/nomad-jobs/3-demo-fluentd.nomad.hcl")
}

#resource "terracurl_request" "enable_audit" {
# method         = "POST"
# name           = "enable_audit"
# response_codes = [204, 400]
# url            = "http://${data.aws_instance.nomad_x86_client.public_ip}:8204/v1/sys/audit/example-audit"
# 
# request_body   = <<EOF
#{
#  "type": "file",
#  "options": {
#    "file_path": "/vault/logs/vault-audit.log"
#  }
#}
#EOF
#
#  headers = {
#    X-Vault-Token = "${data.vault_kv_secret_v2.vault-dev-root-token.data["VAULT_ROOT_TOKEN"]}"
#  }
# max_retry      = 3
# retry_interval = 5
# 
# depends_on = [nomad_job.demo-fluentd]
#}