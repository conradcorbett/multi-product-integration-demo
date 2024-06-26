job "demo-splunk" {
    datacenters = ["dc1"]
    node_pool = "x86"
#    type = "service"

    group "splunk" {
        network {
            mode = "bridge"
            port "http" {
                static = 8443
                to     = 8443
            }
#            port "event" {
#                static = 8088
#                to     = 8088
#          }
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
            name = "demo-splunk-event"
            port = "8088"
            connect{
                sidecar_service {}
            }
        } 
        service {
            name = "demo-splunk-ui"
            port = "8443"
#            address = "${attr.unique.platform.aws.public-ipv4}"
            connect{
                sidecar_service {}
            }
        }         
        task "splunk" {
            resources {
                cpu = 1000
                memory = 600
            }
            driver = "docker"
            config {
                image = "splunk/splunk:8.0.4.1"
                volumes = [
                  "local:/tmp/defaults",
                ]
            }
            template {
              data = <<EOF
ansible_connection: local
ansible_environment: {}
ansible_post_tasks: null
ansible_pre_tasks: null
cert_prefix: https
config:
  baked: default.yml
  defaults_dir: /tmp/defaults
  env:
    headers: null
    var: SPLUNK_DEFAULTS_URL
    verify: true
  host:
    headers: null
    url: null
    verify: true
  max_delay: 60
  max_retries: 3
  max_timeout: 1200
dmc_asset_interval: 3,18,33,48 * * * *
dmc_forwarder_monitoring: false
docker: true
hide_password: false
java_download_url: null
java_update_version: null
java_version: null
retry_delay: 6
retry_num: 60
shc_sync_retry_num: 60
splunk:
  admin_user: admin
  allow_upgrade: true
  app_paths:
    default: /opt/splunk/etc/apps
    deployment: /opt/splunk/etc/deployment-apps
    httpinput: /opt/splunk/etc/apps/splunk_httpinput
    idxc: /opt/splunk/etc/master-apps
    shc: /opt/splunk/etc/shcluster/apps
  appserver:
    port: 8065
  asan: false
  auxiliary_cluster_masters: []
  build_url_bearer_token: null
  cluster_master_url: null
  connection_timeout: 0
  deployer_url: null
  dfs:
    dfc_num_slots: 4
    dfw_num_slots: 10
    dfw_num_slots_enabled: false
    enable: false
    port: 9000
    spark_master_host: 127.0.0.1
    spark_master_webui_port: 8080
  enable_service: false
  exec: /opt/splunk/bin/splunk
  group: splunk
  hec:
    ca: null
    cert: null
    enable: true
    password: null
    port: 8088
    ssl: false
    token: 5e14336d-3a44-4db1-860d-4c9fe67fbc32
  conf:
    - key: inputs
      value:
        directory: /opt/splunk/etc/apps/splunk_httpinput/local
        content:
          http:
            disabled: 0
            enableSSL: 0
    - key: authorize
      value:
        directory: /opt/splunk/etc/system/local/
        content:
          role_admin:
            grantableRoles: admin
            srchIndexesAllowed: '*;_*;vault-audit;vault-metrics'
            srchIndexesDefault: 'main;vault-audit;vault-metrics'
            srchMaxTime: 8640000
    - key: indexes
      value:
        directory: /opt/splunk/etc/apps/search/local/
        content:
          vault-metrics:
            coldPath: $SPLUNK_DB/vault-metrics/colddb
            datatype: metric
            enableDataIntegrityControl: 0
            enableTsidxReduction: 0
            homePath: $SPLUNK_DB/vault-metrics/db
            maxTotalDataSizeMB: 2048
            thawedPath: $SPLUNK_DB/vault-metrics/thaweddb
            archiver.enableDataArchive: 0
            bucketRebuildMemoryHint: 0
            compressRawdata: 1
            enableOnlineBucketRepair: 1
            metric.enableFloatingPointCompression: 1
            minHotIdleSecsBeforeForceRoll: 0
            suspendHotRollByDeleteQuery: 0
            syncMeta: 1
          vault-audit:
            coldPath: $SPLUNK_DB/vault-audit/colddb
            datatype: event
            enableDataIntegrityControl: 0
            enableTsidxReduction: 0
            homePath: $SPLUNK_DB/vault-audit/db
            maxTotalDataSizeMB: 2048
            thawedPath: $SPLUNK_DB/vault-audit/thaweddb
            archiver.enableDataArchive: 0
            bucketRebuildMemoryHint: 0
            compressRawdata: 1
            enableOnlineBucketRepair: 1
            metric.enableFloatingPointCompression: 1
            minHotIdleSecsBeforeForceRoll: 0
            suspendHotRollByDeleteQuery: 0
            syncMeta: 1
    - key: inputs
      value:
        directory: /opt/splunk/etc/apps/splunk_httpinput/local
        content:
          http://Vault Metrics:
            disabled: 0
            index: vault-metrics
            indexes: vault-metrics
            token: 42c0ff33-c00l-7374-87bd-690ac97efc50
            sourcetype: hashicorp_vault_telemetry
          http://Vault Audit:
            disabled: 0
            index: vault-audit
            indexes: vault-audit
            token: 12b8a76f-3fa8-4d17-b67f-78d794f042fb
            sourcetype: hashicorp_vault_audit_log
    - key: web
      value:
        directory: /opt/splunk/etc/system/local
        content:
          settings:
            verifyCookiesWorkDuringLogin: false
            enableSplunkWebSSL: true
            tools.sessions.secure: false
            tools.sessions.forceSecure: false
  home: /opt/splunk
  http_enableSSL: false
  http_enableSSL_cert: null
  http_enableSSL_privKey: null
  http_enableSSL_privKey_password: null
  http_port: 8443
  verify_cookies_work_during_login: false
  idxc:
    discoveryPass4SymmKey: P2sCPCanaj49BMRK5oC0dGXGd+YejlMD
    label: idxc_label
    pass4SymmKey: P2sCPCanaj49BMRK5oC0dGXGd+YejlMD
    replication_factor: 3
    replication_port: 9887
    search_factor: 3
    secret: P2sCPCanaj49BMRK5oC0dGXGd+YejlMD
  ignore_license: false
  kvstore:
    port: 8191
  launch: {}
  license_download_dest: /tmp/splunk.lic
  license_master_url: null
  multisite_master_port: 8089
  multisite_replication_factor_origin: 2
  multisite_replication_factor_total: 3
  multisite_search_factor_origin: 1
  multisite_search_factor_total: 3
  opt: /opt
  pass4SymmKey: null
  password: vtl-password
  pid: /opt/splunk/var/run/splunk/splunkd.pid
  root_endpoint: null
  s2s:
    ca: null
    cert: null
    enable: true
    password: null
    port: 9997
    ssl: false
  search_head_captain_url: null
  secret: null
  service_name: null
  set_search_peers: true
  shc:
    deployer_push_mode: null
    label: shc_label
    pass4SymmKey: LPZIns9px+aAyj7F8sjRbTp1tKCn1K5f
    replication_factor: 3
    replication_port: 9887
    secret: LPZIns9px+aAyj7F8sjRbTp1tKCn1K5f
  smartstore: null
  ssl:
    ca: null
    cert: null
    enable: true
    password: null
  svc_port: 8089
  tar_dir: splunk
  user: splunk
  wildcard_license: false
splunk_home_ownership_enforcement: true
splunkbase_password: null
splunkbase_token: null
splunkbase_username: null
wait_for_splunk_retry_num: 60
EOF

        destination   = "local/default.yml"
        change_mode   = "signal"
        change_signal = "SIGHUP"
            }
            env {
                SPLUNK_START_ARGS = "--accept-license"
                SPLUNK_PASSWORD= "lvm-password"
                SPLUNK_DB = "/var/lib/splunk"
            }
        }
    }
}