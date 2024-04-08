export NOMAD_ADDR="http://nomad-alb-431577002.us-east-1.elb.amazonaws.com"
export NOMAD_TOKEN='06c7b1cc-61bf-f338-751e-112e079373ea'

# Increase the EBS size of the EC2 x86 node

nomad run splunk.nomadv2.hcl
nomad status demo-splunk
nomad stop demo-splunk

