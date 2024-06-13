variable "myvaulttoken" {
  type = string
}

job "demo-vault" {
    datacenters = ["dc1"]
    node_pool = "x86"
#    type = "service"

    group "vault" {
        network {
            mode = "bridge"
            port "http" {
                static = 8204
                to     = 8204
            }
        }
        service {
            name = "demo-vault"
            port = "8204"
            connect{
                sidecar_service {
                  proxy {
#                    transparent_proxy {}
                    upstreams {
                      destination_name = "demo-telegraf"
                      local_bind_port = 8125
                    }                  
                }
            }
          }
        }        
        volume "vaultauditlog" {
          type = "host"
          read_only = "false"
          source = "vaultauditlog"
        }
        task "vault" {
            resources {
                cpu = 200
                memory = 200
            }
            driver = "docker"
            volume_mount {
              volume      = "vaultauditlog"
              destination = "/vault/logs"
              read_only   = false
            }
            config {
                image = "hashicorp/vault:1.16.1"
                volumes = [
                  "local:/vault/config",
                ]
                command = "/bin/sh"
                args = [
                  "-c",
                  "vault server -config=/vault/config --dev --dev-root-token-id=${var.myvaulttoken} > /vault/logs/output.log 2>&1 & sleep 5 && VAULT_ADDR=http://127.0.0.1:8204 vault audit enable file file_path=/vault/logs/vault-audit.log && chmod 777 /vault/logs/vault-audit.log && tail -f /dev/null"
                ]
            }
            template {
              data = <<EOF
log_level = "trace"
ui        = true

storage "file" {
  path = "/vault/file"
}

listener "tcp" {
  address     = "0.0.0.0:8204"
  tls_disable = 1
}

telemetry {
  dogstatsd_addr                 = "{{env "attr.unique.platform.aws.public-ipv4"}}:8125"
  enable_hostname_label          = true
  disable_hostname               = true
  enable_high_cardinality_labels = "*"
}
EOF
        destination   = "local/main.hcl"
        change_mode   = "signal"
        change_signal = "SIGHUP"
            }
        }
    }
}