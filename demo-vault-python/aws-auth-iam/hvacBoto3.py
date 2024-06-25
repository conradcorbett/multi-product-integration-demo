import boto3
import hvac
import json

session = boto3.Session()
credentials = session.get_credentials()
print(credentials.access_key)
print(credentials.secret_key)
print(credentials.token)

client = hvac.Client()
role = 'vault-role-for-aws-ec2role'
client.auth.aws.iam_login(credentials.access_key, credentials.secret_key, credentials.token, role=role)

secret_path = 'kv/data/test/ec2'
read_secret_result = client.read(secret_path)
print(read_secret_result)
print(read_secret_result['data']['data']['api-key'])