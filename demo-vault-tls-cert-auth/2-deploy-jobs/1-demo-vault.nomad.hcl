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
            }
            vault {
                policies = ["vault-cert"]
                change_mode   = "restart"              
            }
            template {
              data = <<EOF
{{ with secret "secret/data/vault/cert" }}{{ .Data.data.certificate }}{{ end }}
EOF
        destination   = "local/vault-tls-certificate.pem"
            }
            template {
              data = <<EOF
{{ with secret "secret/data/vault/cert" }}{{ .Data.data.issuing_ca }}{{ end }}
EOF
        destination   = "local/vault-tls-issuing-ca.pem"
            }
            template {
              data = <<EOF
{{ with secret "secret/data/vault/cert" }}{{ .Data.data.private_key }}{{ end }}
EOF
        destination   = "local/vault-tls-private-key.pem"
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
  tls_disable = 0
  tls_cert_file = "/vault/config/vault-tls-certificate.pem"
  tls_key_file = "/vault/config/vault-tls-private-key.pem"
}

telemetry {
  dogstatsd_addr                 = "127.0.0.1:8125"
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