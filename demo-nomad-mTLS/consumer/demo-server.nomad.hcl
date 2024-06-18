job "demo-server" {
    datacenters = ["dc1"]
    node_pool = "x86"
    type = "service"
    
    group "server" {
        network {
            mode = "bridge"

            port "http" {
                static = 3101
                to     = 3101
            }
        }
        service {
            name = "demo-server"
            port = "http"
            address = "${attr.unique.platform.aws.public-ipv4}"

            connect {
                sidecar_service {
                    proxy {
                        upstreams {
                            destination_name = "demo-mongodb"
                            local_bind_port  = 27017
                        }
                    }
                }
            }
        }
        task "server" {
            driver = "docker"
            vault {
                policies = ["pki-policy-server"]
                change_mode   = "restart"
            }
            template {
  data = <<EOH
{{ with pkiCert "pki/issue/mtls" "common_name=server.seesquared.local" }}
{{- .Cert -}}
{{ end }}
EOH
  destination   = "secrets/certificate.crt"
  change_mode   = "restart"
}

template {
  data = <<EOH
{{ with pkiCert "pki/issue/mtls" "common_name=server.seesquared.local" }}
{{- .CA -}}
{{ end }}
EOH
  destination   = "secrets/ca.crt"
  change_mode   = "restart"
}

template {
  data = <<EOH
{{ with pkiCert "pki/issue/mtls" "common_name=server.seesquared.local" }}
{{- .Key -}}
{{ end }}
EOH
  destination   = "secrets/private_key.key"
  change_mode   = "restart"
}
            config {
                image = "huggingface/mongoku:latest"
            }
        }
    }
} 