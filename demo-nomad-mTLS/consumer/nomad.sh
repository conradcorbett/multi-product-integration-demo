# Get NOMAD_ADDR from output in 5_nomad-cluster workspace in TFC
export NOMAD_ADDR=http://nomad-alb-471074398.us-east-1.elb.amazonaws.com
# Get Nomad token stored in Vault
vault kv get -mount=hashistack-admin/ nomad_bootstrap/SecretID
export NOMAD_TOKEN="06463869-8757-e1a9-f9cb-78d16ce5bbf2"

nomad node status

nomad run client.nomad.hcl
nomad service info demo-client
nomad job status

#Get the public IP address of the node
NODE_ID=$(nomad node pool nodes -json x86 | jq -r ".[0].ID")
CLIENT_IP=$(nomad node status -json a3c3335e-7b96-fe37-a105-289818a8c25b | jq -r '.Attributes."unique.platform.aws.public-ipv4"')
CLIENT_IP=$(nomad node status -json $(nomad node pool nodes -json x86 | jq -r ".[0].ID") | jq -r '.Attributes."unique.platform.aws.public-ipv4"')

curl -s http://$CLIENT_IP:3100 | jq -r ".env.NOMAD_JOB_NAME"

# in nomad UI, open exec shell to job alloc, look in secrets folder for the certs, exec in with /bin/sh
apk update && apk add curl && apk add openssl
openssl x509 -in /secrets/certificate.crt -noout -subject -dates
subject=CN = client.seesquared.local
notBefore=Mar 27 23:51:31 2024 GMT
notAfter=Mar 28 00:52:00 2024 GMT

openssl x509 -in /secrets/certificate.crt -noout -dates
notBefore=Mar 28 00:44:58 2024 GMT
notAfter=Mar 28 01:45:28 2024 GMT

# Alternatively, use boundary to connect to your nomad node, then your nomad allocation

nomad stop demo-client