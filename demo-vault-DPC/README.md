# Quick demo to show how Vault's Dynamic Provider Credentials can be used with TFC

## Producer
In TFC UI, create the producer workspace under the hashistack project.
In the producer folder, run terraform init, then terraform apply
The terraform code will create a secret in Vault, a Vault policy to access the secret, and a jwt auth role for TFC to use to fetch the secret.
You can view the created secret using the Vault UI after you run terraform: secrets > nomadsecret > secret

## Consumer
The Consumer workspace should already be created from the previous step.
The applicable environment variables are already loaded, the only one that needed to be updated was the Vault role, which was overwritten.
Run terraform from the CLI in the consumer folder, check the output to see the secret value retrieved from Vault.

## Cleanup
Run terraform destroy on consumer workspace from CLI.
Run terraform destroy on producer workspace from CLI. Once destroy is complete, delete the producer workspace in TFC using the UI.