# Deploy job to Nomad
The control workspace will create the workload workspace in TFC, but it does not plan/apply the workspace.
To deploy a nomad job, from the TFC UI, plan/apply the workload workspace.
The job deploys mongodb and a frontend interface to interact with mongo. Access the front end over port 3100 and the public IP of the EC2 x86 node.
You can add a consul intention to allow the front end to connect to mongo.
