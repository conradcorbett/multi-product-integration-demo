# Setup
## Get the nomad addr from workspace 5 output in TFC
export NOMAD_ADDR="http://nomad-alb-532004401.us-east-1.elb.amazonaws.com"
## Get the nomad token from statefile in TFC, or read it from HCP vault kv
export NOMAD_TOKEN='f85c7674-fe40-abc7-aa3b-55887ccd95fe'

# Deploy Vault
nomad run 1-demo-vault.nomad.hcl
## Get Vault token from Nomad UI logs > stdout
export VAULT_ADDR=http://54.234.235.178:8204
export VAULT_ADDR=http://$(nomad node status -json $(nomad node pool nodes -json x86 | jq -r ".[0].ID") | jq -r '.Attributes."unique.platform.aws.public-ipv4"'):8204
echo $VAULT_ADDR
export VAULT_TOKEN=hvs.GQUqx98NJ1fg8rmd5nEkExqp
vault audit enable file file_path=/vault/logs/vault-audit.log
vault write sys/internal/counters/config enabled=enable

# Deploy Splunk
nomad run 2-demo-splunkv2.nomad.hcl 
nomad status demo-splunk
If splunk deploys properly, the last line in the logs should be: "Ansible playbook complete, will begin streaming var/log/splunk/splunkd_stderr.log"
Connect to splunk over web UI - admin / lvm-password - https://ec2-54-234-235-178.compute-1.amazonaws.com:8443/

# Deploy Fluentd
Removed following line from fluentd config:   host "{{env "attr.unique.platform.aws.public-ipv4"}}"
Replaced with:   host "127.0.0.1"
nomad run 3-demo-fluentd.nomad.hcl

# Deploy Telegraf
nomad run 4-demo-telegraf.nomad.hcl 

## NOTE TODO - Only fluentd for audit log is functioning, need to go and adjust code to get telegraf working with consul service mesh (change to local IP on 127.0.0.1 so we can connect over mesh)

# Generate some Vault usage
vault secrets enable -version=2 kv
for i in {1..10}
  do
    printf "."
    vault kv put kv/$i-secret-10 id="$(uuidgen)" >> step4.log 2>&1
done
for i in {1..10}
  do
    printf "."
    vault kv put kv/$i-secret-10 id="$(uuidgen)" >> step4.log 2>&1
done
vault policy write sudo - << EOT
// Example policy: "sudo"
path "*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
EOT
vault auth enable userpass
vault write auth/userpass/users/learner \
  password=vtl-password \
  token_ttl=120m \
  token_max_ttl=140m \
  token_policies=sudo
for i in {1..10}
  do
    printf "."
    vault login \
      -method=userpass \
      username=learner \
      password=vtl-password >> step4.log 2>&1
done
for i in {1..20}
  do
    printf "."
    vault token create -policy=default >> step4.log 2>&1
done
for i in {1..10}
  do
    printf "."
    vault write auth/userpass/users/learner$i password=vtl-password token_ttl=120m token_max_ttl=140m token_policies=sudo
done
for i in {1..10}
  do
    printf "."
    vault login -method=userpass username=learner$i password=vtl-password >> step4.log 2>&1
    vault secrets list >> step4.log 2>&1
done

# Splunk commands
## Search & Reporting > Analytics > Metrics > Vault
## Search & Reporting > In Search bar, can put commands below
## Clients
index="vault-audit"  sourcetype="hashicorp_vault_audit_log" auth.accessor=* auth.entity_id=*
| eval month = strftime(_time, "%B %Y")
| stats dc(auth.entity_id) as entity_count , first(_time) as last_event,last(_time) as first_event by sourcetype
| eval StartTime=strftime(first_event, "%Y-%m-%dT%H:%M:%S")
| eval EndTime=strftime(last_event, "%Y-%m-%dT%H:%M:%S")
| appendcols
  [ search index="vault-audit" sourcetype="hashicorp_vault_audit_log" auth.accessor=* NOT auth.entity_id=*
  | eval month = strftime(_time, "%b %Y")
  | stats dc(auth.accessor) as accessor_count by sourcetype]
| addtotals fieldname=Total entity_count, accessor_count

## Token TTLs
| mstats sum(vault.token.creation.value) AS count WHERE index=vault-metrics BY creation_ttl
## Tokens by mount point
| mstats sum(vault.token.creation.value) AS count WHERE index=vault-metrics AND cluster=vault-cluster-80c9165f AND creation_ttl=+Inf BY mount_point

# Retrieve secret from Vault as logged in user
VAULT_TOKEN="hvs.CAESIJIwK-x0ryG6nboj2bnl-n5zMlyZ7dkANihSAdJyhYT5Gh4KHGh2cy5rWndWZ3hjOHlTS3d4bTRtUXQ1WWdPVXg" vault kv get -mount=kv 2-secret-10

## Count how many times a user has accessed Vault
index="vault-audit"  sourcetype="hashicorp_vault_audit_log" auth.accessor=* auth.entity_id=* auth.display_name="userpass-learner10"
| eval month = strftime(_time, "%B %Y")
| stats count(auth.entity_id) as entity_count , first(_time) as last_event,last(_time) as first_event by sourcetype


## Count how many clients in an auth mount:
index="vault-audit"  sourcetype="hashicorp_vault_audit_log" auth.accessor=* auth.entity_id=* response.mount_point="auth/userpass2/"
| eval month = strftime(_time, "%B %Y")
| stats dc(auth.entity_id) as entity_count , first(_time) as last_event,last(_time) as first_event by sourcetype
| eval StartTime=strftime(first_event, "%Y-%m-%dT%H:%M:%S")
| eval EndTime=strftime(last_event, "%Y-%m-%dT%H:%M:%S")

## Count how many clients have logged into Vault, then used their token to actually do something in Vault
index="vault-audit"  sourcetype="hashicorp_vault_audit_log" request.client_id=*
| eval month = strftime(_time, "%B %Y")
| stats dc(auth.entity_id) as entity_count , first(_time) as last_event,last(_time) as first_event by sourcetype
| eval StartTime=strftime(first_event, "%Y-%m-%dT%H:%M:%S")
| eval EndTime=strftime(last_event, "%Y-%m-%dT%H:%M:%S")