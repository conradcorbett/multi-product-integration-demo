# Helpful links:
https://github.com/hashicorp/terraform-aws-vault/blob/master/examples/vault-consul-ami/auth/sign-request.py
https://github.com/hashicorp/terraform-aws-vault/blob/master/examples/vault-iam-auth/user-data-auth-client.sh
https://gist.github.com/joelthompson/378cbe449d541debf771f5a6a171c5ed?permalink_comment_id=3237123#gistcomment-3237123


Demo to setup AWS auth in Vault with type IAM:
Instructions: https://developer.hashicorp.com/vault/tutorials/manage-hcp-vault-dedicated/vault-auth-method-aws#vault-auth-method-aws

Use doormat to acces AWS console. When creating the AWS IAM user access_key and secret_key for Vault (https://developer.hashicorp.com/vault/tutorials/manage-hcp-vault-dedicated/vault-auth-method-aws#create-aws-iam-user-for-hcp-vault-dedicated-auth-method), use your doormat demo user: arn:aws:iam::692750136508:user/demo-conrad.corbett@hashicorp.com

# Testing the setup
Log onto one of the nomad servers (can use boundary for this)
Might need to switch to sudo: sudo su -
Install the vault binary
vault login -output-curl-string -method=aws role=vault-role-for-aws-ec2role
VAULT_TOKEN=$(vault login -format=json -method=aws role=vault-role-for-aws-ec2role | jq -r .auth.client_token)
VAULT_TOKEN=$VAULT_TOKEN vault kv get kv/test/ec2
VAULT_TOKEN=$VAULT_TOKEN vault read kv/data/test/ec2

# Generating iam_request_body with python3:
https://gist.github.com/joelthompson/378cbe449d541debf771f5a6a171c5ed?permalink_comment_id=3237123#gistcomment-3237123
When using the vault binary to login, it automatically generates iam_request_body, iam_request_url, and iam_request_headers. If you are not using the Vault binary, then you will need to generate these using python or Go.
Use a venv:
apt install python3.11-venv
python3 -m venv .venv
source .venv/bin/activate
pip install boto3
python3 vault_aws_auth_py3.py

Once you have iam_request_body, iam_request_url, and iam_request_headers, you can pass these to login API to log into Vault and get a Vault token in return:
https://developer.hashicorp.com/vault/api-docs/auth/aws#sample-payload-8

# Testing the setup with HVAC
If customer can't use vault binary to login, they can instead use HVAC which simplifies the process as you don't need to generate iam_request_body, iam_request_url, and iam_request_headers.
pip install hvac
python3 hvacBoto3.py
