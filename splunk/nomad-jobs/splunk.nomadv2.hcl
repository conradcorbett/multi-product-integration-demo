job "demo-splunk" {
    datacenters = ["dc1"]
    node_pool = "x86"
    type = "service"

    group "splunk" {
        network {
            mode = "bridge"
            port "http" {
                static = 8000
                to     = 8000
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

        service {
            name = "splunk-http"
            port = "8443"
            address = "${attr.unique.platform.aws.public-ipv4}"

            connect{
                sidecar_service {}
            }
        } 

        task "splunk" {
            driver = "docker"
            config {
                image = "splunk/splunk:8.0.4.1"
                volumes = ["local/default.yml:/tmp/defaults/default.yml" ]
            }
            env {
                SPLUNK_START_ARGS = "--accept-license"
                SPLUNK_PASSWORD= "lvm-password"
#                SPLUNK_DB = "/var/lib/splunk"
                SPLUNK_USER = "root"
            }
        }
    }
}