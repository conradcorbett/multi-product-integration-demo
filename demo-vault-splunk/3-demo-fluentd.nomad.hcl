job "demo-fluentd" {
    datacenters = ["dc1"]
    node_pool = "x86"
#    type = "service"

    group "fluentd" {
        network {
            mode = "bridge"
        }
        service {
            name = "demo-fluentd"
            connect{
                sidecar_service {
                  proxy {
                    upstreams {
                      destination_name = "demo-splunk-event"
                      local_bind_port = 8088
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
        task "fluentd" {
            resources {
                cpu = 800
                memory = 200
            }
            driver = "docker"
            volume_mount {
              volume      = "vaultauditlog"
              destination = "/vault/logs"
              read_only   = false
            }
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
  host "127.0.0.1"
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