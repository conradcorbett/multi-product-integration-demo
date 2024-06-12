The Control Workspace will deploy 9_splunk-tf workspace in TFC. Initiate a run of the 9_splunk-tf workspace from the TFC UI to build the splunk demo.

Self-hosted Vault retrieves a root token stored in HCP Vault. TFC uses dynamica provider credentials to authenticate to HCP Vault, so it is then able to get the root token from HCP Vault. The vault token is created from a TF environment variable in 5_nomad_cluster. An alternative way to do this would be to give the Nomad job permissions to read the secret from Vault.

The nomad provider needs a nomad token and nomad address. The nomad token is stored in HCP, TFC is able to authenticate using DPC to retrieve the nomad token. Using workspace outputs, we get the nomad address.

The nomad jobs are automatically added to the consul service mesh.

In Splunk UI: Settings > Indexes > vault-audit should not have events until the intention is created in Consul and there is audit log activity.

vault audit enable file file_path=/vault/logs/vault-audit.log
vault write sys/internal/counters/config enabled=enable
vault auth enable userpass
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