job "demo-telegraf" {
    datacenters = ["dc1"]
    node_pool = "x86"
#    type = "service"

    group "telegraf" {
        network {
            mode = "bridge"
            port "stats" {
                static = 8125
                to     = 8125
            }
        }
        service {
            name = "demo-telegraf"
#            port = "8125"
#            address = "${attr.unique.platform.aws.public-ipv4}"
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
        task "telegraf" {
            resources {
                cpu = 400
                memory = 250
            }
            driver = "docker"
            config {
                image = "telegraf:1.12.6"
                volumes = [
                  "local:/etc/telegraf",
                ]
            }
            template {
              data = <<EOF
# Telegraf Configuration
# Global tags relate to and are available for use in Splunk searches
# Of particular note are the index tag, which is required to match the
# configured metrics index name and the cluster tag which should match the
# value of Vault's cluster_name configuration option value.
[global_tags]
  index="vault-metrics"
  datacenter = "us-east-1"
  role       = "vault-server"
  cluster    = "vtl"
# Agent options around collection interval, sizes, jitter and so on
[agent]
  interval = "10s"
  round_interval = true
  metric_batch_size = 1000
  metric_buffer_limit = 10000
  collection_jitter = "0s"
  flush_interval = "10s"
  flush_jitter = "0s"
  precision = ""
  hostname = ""
  omit_hostname = false
# An input plugin that listens on UDP/8125 for statsd compatible telemetry
# messages using Datadog extensions which are emitted by Vault
[[inputs.statsd]]
  protocol = "udp"
  service_address = ":8125"
  metric_separator = "."
  datadog_extensions = true
# An output plugin that can transmit metrics over HTTP to Splunk
# You must specify a valid Splunk HEC token as the Authorization value
[[outputs.http]]
  url = "http://{{env "attr.unique.platform.aws.public-ipv4"}}:8088/services/collector"
  data_format="splunkmetric"
  splunkmetric_hec_routing=true
  [outputs.http.headers]
    Content-Type = "application/json"
    Authorization = "Splunk 42c0ff33-c00l-7374-87bd-690ac97efc50"
# Read metrics about cpu usage using default configuration values
[[inputs.cpu]]
  percpu = true
  totalcpu = true
  collect_cpu_time = false
  report_active = false
  fieldpass = ["usage_idle","usage_iowait","usage_irq","usage_nice","usage_softirq","usage_steal","usage_system","usage_user"]
# Read metrics about memory usage
[[inputs.mem]]
  # No configuration required
# Read metrics about network interface usage
[[inputs.net]]
  # Uses default configuration
# Read metrics about swap memory usage
[[inputs.swap]]
  # No configuration required
# Read metrics about disk usage using default configuration values
[[inputs.disk]]
  ## By default stats will be gathered for all mount points.
  ## Set mount_points will restrict the stats to only the specified mount points.
  ## mount_points = ["/"]
  ## Ignore mount points by filesystem type.
  ignore_fs = ["tmpfs", "devtmpfs", "devfs", "overlay", "aufs", "squashfs"]
[[inputs.diskio]]
  # devices = ["sda", "sdb"]
  # skip_serial_number = false
[[inputs.kernel]]
  # No configuration required
[[inputs.linux_sysctl_fs]]
  # No configuration required
[[inputs.net]]
  # Specify an interface or all
  # interfaces = ["enp0s*"]
[[inputs.netstat]]
  # No configuration required
[[inputs.processes]]
  # No configuration required
[[inputs.procstat]]
 pattern = "(vault)"
[[inputs.system]]
  # No configuration required
EOF

        destination   = "local/telegraf.conf"
        change_mode   = "signal"
        change_signal = "SIGHUP"
            }
        }
    }
}