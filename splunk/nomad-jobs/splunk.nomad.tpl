job "demo-mongodb" {
    datacenters = ["dc1"]
    node_pool = "x86"
    type = "service"

    group "splunk" {
        network {
            mode = "bridge"
            port "http" {
                static = 8443
                to     = 8443
            }
        }

        service {
            name = "splunk"
            port = "8443"
            address = "${attr.unique.platform.aws.public-ipv4}"

            connect{
                sidecar_service {}
            }
        } 

        task "splunk" {
            driver = "docker"
            template {
                data = <<EOF
    $(default_yml)
    EOF
                destination = "/tmp/defaults/default.yml"
            }
            config {
                image = "splunk/splunk:8.0.4.1"
            }
            env {
                SPLUNK_START_ARGS = "--accept-license"
                SPLUNK_PASSWORD= "lvm-password"
                SPLUNK_DB = "/var/lib/splunk"
            }
        }
    }
}