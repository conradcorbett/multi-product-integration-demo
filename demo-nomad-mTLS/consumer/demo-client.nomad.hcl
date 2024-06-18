job "demo-client" {
    datacenters = ["dc1"]
    node_pool = "x86"
    type = "service"
    
    group "client" {
        network {
            mode = "bridge"

            port "http" {
                static = 3100
                to     = 3100
            }
        }
        service {
            name = "demo-client"
            port = "http"
            address = "${attr.unique.platform.aws.public-ipv4}"

            connect {
                sidecar_service {
                    proxy {
                    }
                }
            }
        }
        task "client" {
            driver = "docker"
            user = "root"
            env {
              HTTP_PORT = "3100"
              ECHO_INCLUDE_ENV_VARS = "1"
            }
            vault {
                policies = ["pki-policy-client"]
                change_mode   = "restart"
            }
            template {
  data = <<EOH
{{ with pkiCert "pki/issue/mtls" "common_name=client.seesquared.local" }}
{{- .Cert -}}
{{ end }}
EOH
  destination   = "secrets/certificate.crt"
  change_mode   = "restart"
}

template {
  data = <<EOH
{{ with pkiCert "pki/issue/mtls" "common_name=client.seesquared.local" }}
{{- .CA -}}
{{ end }}
EOH
  destination   = "secrets/ca.crt"
  change_mode   = "restart"
}

template {
  data = <<EOH
{{ with pkiCert "pki/issue/mtls" "common_name=client.seesquared.local" }}
{{- .Key -}}
{{ end }}
EOH
  destination   = "secrets/private_key.key"
  change_mode   = "restart"
}
            config {
                image = "mendhak/http-https-echo"
#                command = "/bin/sh"
#                args = ["-c", "echo hiiii"]
            }
        }
    }
} 