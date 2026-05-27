---
command: region
description: Override the default AWS region for EC2 provisioning (default us-east-1).
allowed-tools: Bash, AskUserQuestion
---

# apsy:region — AWS region

Set the AWS region used by the `ec2` deploy backend (provisioning + DNS):
`bin/apsy-config.sh set APSY_AWS_REGION <region>` (default `us-east-1`).
