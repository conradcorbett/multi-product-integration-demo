# Vault Certificate Demo and Nomad Template

The purpose of this demo is to use nomad's templating capabilities to insert a certificate generated by Vault into the nomad allocation.

In the producer folder, run the commands in vault.sh. You will need to update the variables.
Keep in mind, the Nomad cluster is originally configured to use a hard coded Vault token. This Vault token needs to have the correct policies associated with it. See line 70 in main.tf in 5_nomad-cluster folder.

The consumer folder has a nomad job that will save the vault generated certs into /secrets in the nomad allocation. The certificates are automatically renewed prior to expiring.
