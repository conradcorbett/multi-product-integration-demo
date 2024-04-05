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
        }

        service {
            name = "splunk"
            port = "8000"
            address = "${attr.unique.platform.aws.public-ipv4}"

            connect{
                sidecar_service {}
            }
        } 

        task "splunk" {
            driver = "docker"
            config {
                image = "splunk/splunk:8.0.4.1"
            }
            env {
                SPLUNK_START_ARGS = "--accept-license"
                SPLUNK_PASSWORD= "lvm-password"
            }
        }
    }
}