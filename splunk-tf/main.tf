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
}

#resource "null_resource" "wait_for_db" {
#  depends_on = [nomad_job.mongodb]
#
#  provisioner "local-exec" {
#    command = "sleep 10 && bash wait-for-nomad-job.sh ${nomad_job.mongodb.id} ${data.terraform_remote_state.nomad_cluster.outputs.nomad_public_endpoint} ${data.vault_kv_secret_v2.bootstrap.data["SecretID"]}"
#  }
#}
#
#data "consul_service" "demo-vault_service" {
##    depends_on = [ null_resource.wait_for_db ]
#    name = "demo-vault"
#}
#
#resource "vault_database_secrets_mount" "mongodb" {
#  depends_on = [
#    null_resource.wait_for_db
#  ]
#  lifecycle {
#    ignore_changes = [
#      mongodb[0].password
#    ]
#  }
#  path = "mongodb"
#
#  mongodb {
#    name                 = "mongodb-on-nomad"
#    username             = "admin"
#    password             = "password"
#    connection_url       = "mongodb://{{username}}:{{password}}@${[for s in data.consul_service.mongo_service.service : s.address][0]}:27017/admin?tls=false"
#    max_open_connections = 0
#    allowed_roles = [
#      "demo",
#    ]
#  }
#}
#
#resource "null_resource" "mongodb_root_rotation" {
#  depends_on = [
#    vault_database_secrets_mount.mongodb
#  ]
#  provisioner "local-exec" {
#    command = "curl --header \"X-Vault-Token: ${data.terraform_remote_state.hcp_clusters.outputs.vault_root_token}\" --request POST ${data.terraform_remote_state.hcp_clusters.outputs.vault_public_endpoint}/v1/${vault_database_secrets_mount.mongodb.path}/rotate-root/mongodb-on-nomad"
#  }
#}
#
#resource "vault_database_secret_backend_role" "mongodb" {
#  name    = "demo"
#  backend = vault_database_secrets_mount.mongodb.path
#  db_name = vault_database_secrets_mount.mongodb.mongodb[0].name
#  creation_statements = [
#    "{\"db\": \"admin\",\"roles\": [{\"role\": \"root\"}]}"
#  ]
#}
#
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

resource "terracurl_request" "enable_audit" {
 method         = "POST"
 name           = "enable_audit"
 response_codes = [200]
 url            = "http://${data.aws_instance.nomad_x86_client.public_ip}:8204/v1/sys/audit/example-audit"
 
 request_body   = <<EOF
{
  "type": "file",
  "options": {
    "file_path": "/vault/logs/vault-audit.log"
  }
}
EOF

  headers = {
    X-Vault-Token = "${data.vault_kv_secret_v2.vault-dev-root-token.data["VAULT_ROOT_TOKEN"]}"
  }
 max_retry      = 7
 retry_interval = 10
 
 depends_on = [time_sleep.wait_15_seconds_2]
}