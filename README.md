## ECS Service Discover & Service Connect Demo

This repo contains the source and docker-compose files for the deployment of two services that will be deployed
on ECS as follows:
* service1 - it will use Service Connect which is detailed for how to do it manually in this README (we can not
  do it automatically because it is not supported by ecs-compose-x).
* service2 - it will be deployed with Service Discovery through ecs-compose-x recipes

Additional resources are created through ecs-compose-x to facilitate the testing:
* ECS cluster with VPCs for Apps, Public and Storage.
* ALB for service1, to expose it publicly, without configuration for Service Discovery & Service Connect.
* Cloudmap private namespace which will be used by service2 in its Service Discovery configuration.

## Steps for deployment

1. After cloning the repo, install ecs-compose-x as described here: https://docs.compose-x.io/installation.html.

2. Set up a test account AWS CLI profile with default region in `eu-west-2` and set the followings variables in the terminal session:
```bash
export AWS_PROFILE=<test_account_profile>
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity | jq -r .Account)
export REGISTRY_URI="${AWS_ACCOUNT_ID}.dkr.ecr.eu-west-2.amazonaws.com/"

```

3. Create an ECR repo for the demo image:
```bash
aws ecr create-repository --repository-name ecs-sd-sc-demo
```

4. Login with Docker to the ECR repo:
```bash
aws ecr get-login-password --region eu-west-2 | docker login --username AWS --password-stdin ${REGISTRY_URI}
```

5. Run the ecs-compose-x command to deploy:
```bash
ecs-compose-x plan -f docker-compose.yaml -f aws-compose-x.yaml -n ecs-sd-sc-demo
```

This command will take a few seconds and at the end will require input to execute the Cloud Formation change sets.
If asked to cleanup the Cloud Formation stack, choose `No`. The stack can be inspected under Cloud Formation in AWS Console,
in terms of progress.

## Manual changes after deployment, before testing

Once the CFN stack is created/completed, we'll need to proceed with the manual changes to enable testing the SD-SC demo.
There are some manual steps we'll need to do after deploying through ecs-compose-x which relate to:
1. adding an inbound rule for the service1 ALB's security group, for TCP 3000 with anywhere/IpV4 source.
2. update the portmappings for service1 with AWS Console, so that it has a port name = 'http'.
3. enable service connect in client mode for service1.
4. update service1 service-connect configuration through AWS CLI to enable it in server mode as well.

## Testing

1. Take the public DNS of the service1's ALB, and run, for which you should get some plain HTML:
```bash
curl <dns_name>:3000/
```

2. We should test now the Service Connect proxy by calling the following command, again with a 
   plain HTML response for a successful response:
```bash
curl <dns_name>:3000/call1
```

3. At the end we'll test the Service Discovery endpoints by calling the following command, again
   with a plain html response for a successful response:
```bash
curl <dns_name>:3000/call2
```