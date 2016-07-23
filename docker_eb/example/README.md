# Getting Started

This is an example project that provides all the necessary code for a simple
Go web app, a Makefile with target commands for Docker and Elastic Beanstalk
workflows and a deploy script for deploying new versions to your EB
environment.

## Create a new project from this Example code

```bash
$ git clone https://github.com/awonak/presentations
$ cp presentations/docker_eb/example ./
$ cd example
$ git init
```

## Create the ECR Repo

We need to create the reposiory in ECR if it does not yet exist and set
the `$REGISTRY_HOST` environment variable as well as set `$EB_BUCKET` to your
S3 bucket used to store zipped application bundles.

```
$ aws ecr create-repository --repository-name example
{
    "repository": {
        "registryId": "<account_id>",
        "repositoryName": "example",
        "repositoryArn": "arn:aws:ecr:us-west-2:<account_id>:repository/example",
        "repositoryUri": "<account_id>.dkr.ecr.us-west-2.amazonaws.com/example"
    }
}
$ export REGISTRY_HOST=<account_id>.dkr.ecr.us-west-2.amazonaws.com
$ export EB_BUCKET=<your s3 bucket>
```

## Create the Elastic Beanstalk Environment

Run the aws cli command to create a environment in Elastic Beanstalk for us to deploy the app. Note that when we run this command, it will build the Dockerfile directly on your EB environment. Subsequent deploys will deploy a specified Docker image from ECR.

```bash
# This only needs to be run the first time you initialize a repo for EB
$ eb init

# This only needs to be run when creating a new EB environment
$ eb create example-env --envvars=GIN_MODE=release
```

## Build the Docker container

Using the base image `golang:1.6` Docker will create a container and compile
the go binary inside the container.

```bash
$ make build
```

Once the container is built, we can run the container and test it out.

```bash
$ make run
```

With the container running, test it in your browers, likely http://localhost:8080

## Tag the repo version

Now that we are ready to publish this version, lets tag the repo with the latest version.

```bash
$ git tag v1.0.1
```

## Tag and Publish the Docker Image

Now that we have the continer working, let's commit & tag it to a Docker
Image, publish that image to the EC2 Container Repository, and create an EB
Application Bundle then copy it to S3.

```bash
$ make publish
```

## Deploy to Elastic Beanstalk

```bash
$ ./deploy.sh v1.0.1 example-env
```

Now you can log into the Elastic Beanstalk console and watch the progress. Once the deploy is complete, your web app is live! Success, have a 🍺