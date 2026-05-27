---
command: type
description: Override the EC2 instance type for provisioning (default auto-sized m7i.{N}xlarge).
allowed-tools: Bash, AskUserQuestion
---

# apsy:type — EC2 instance type

Set the EC2 instance type used by the `ec2` deploy backend:
`bin/apsy-config.sh set APSY_EC2_TYPE <type>`. Default is auto-sized **`m7i.{N}xlarge`** by estimated
experiment size — `xlarge` = 16 GB, `2xlarge` = 32 GB, `4xlarge` = 64 GB, ….
