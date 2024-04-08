job "demo-fluentd" {
    datacenters = ["dc1"]
    node_pool = "x86"
#    type = "service"

    group "fluentd" {
        network {
            mode = "bridge"
            port "http" {
                static = 8443
                to     = 8443
            }
            port "event" {
                static = 8088
                to     = 8088
          }
            port "mgmt" {
                static = 8089
                to     = 8089
          }
            port "data" {
                static = 9997
                to     = 9997
          }
        }

#        service {
#            name = "splunk-http"
#            port = "8443"
#            address = "${attr.unique.platform.aws.public-ipv4}"
#
#            connect{
#                sidecar_service {}
#            }
#        } 

        task "fluentd" {
            driver = "docker"
            config {
                image = "brianshumate/fluentd-splunk-hec:0.0.2"
                volumes = [
                  "local:/fluentd/etc",
                ]
            }
            template {
              data = <<EOF
<source>
@type tail
  path /vault/logs/vault-audit.log
  pos_file /vault/logs/vault-audit-log.pos
  <parse>
    @type json
    time_format %iso8601
  </parse>
  tag vault_audit
</source>
<filter vault_audit>
  @type record_transformer
  <record>
    cluster v5
  </record>
</filter>
<match vault_audit.**>
  @type splunk_hec
  host 127.0.0.1
  port 8088
  token 12b8a76f-3fa8-4d17-b67f-78d794f042fb
</match>
EOF

        destination   = "local/fluent.conf"
        change_mode   = "signal"
        change_signal = "SIGHUP"
            }
        }
    }
}