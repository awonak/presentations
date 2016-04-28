#Docker EB

## Here's the problem

We had a few small simple web services written in go and python that need to be deployed to production servers. At the time, we used vagrant + salt to provision an EC2 instance to deploy most apps. For go, we did not have a formal process for deploying a go binary to a production server. When we wanted to spin up a new instance of an existing application, there were several manual steps of creating a new ec2 instance, copying a provisioning script, then somtimes deploying code / additional boostrap steps to complete the process.  For our small web services in both go and python, this approach was not satisfactory. We decided to investigate alternative approaches for managing server instances, provisioning and deployment.

Enter Docker & Elastic Beanstalk.

## What needed to change?

The problem was broken up into 2 sections:

* Application environment configuration (what is running)
* Server environment configuration (where is it running)

We wanted to be able to define the system packages and configuration necessary for the application to run and we wanted to be able to define and configure one or many server instances to run the application.

Using Docker, we were able to design a consistent application environment that is guaranteed to run the same on a development machine as it would in production. The application environment can define things like required system packages, environment variables and what port to communicate on.

Using Elastic Beanstalk, we are able to define a server configuration to run our Docker container. The server environment can define things like auto scaling rules, load balancing and nginx configurations for communicating with the app.

## Make it so!

First, we needed to get an application running locally using docker.

```makefile
FROM golang:1.5.2

# Copy the app source
RUN mkdir -p /go/src/github.com/foodgenius/restribution
WORKDIR /go/src/github.com/foodgenius/restribution
ADD . /go/src/github.com/foodgenius/restribution

# Install the application
RUN go install

# restribution runs on port 8080 so exposed that
EXPOSE 8080
CMD ["restribution", "http"]
```

Second, were needed to build an Elastic Beanstalk environment to run our container.

```bash
$ eb create restribution-env \
    --cname=restribution-env \
    --instance_type=m1.small \
    --instance_profile=restribution \
    --tags=Application=restribution,Service=eb \
    --envvars=FSEL_HOST=fsel.us-east-1.elasticbeanstalk.com,\
DATASET_BUCKET=deploy-foodgenius,\
DATASET_TABLE=datasets,\
TRAINED_CLASSIFIER_TABLE=trained_classifiers
```

Which can be saved as a config and have new envs created from that config:

```bash
$ eb create restribution-test-feature --cname=restribution-test-feature --cfg=restribution-config
```

With the application environment and server environment created and reproducable, we now need a mechanism for handling deployments. Prior to every deploy, we want to tag the version of the software so we know exactly what version of the code is in production for each app. Each application version tag is semantically versioned with X<major>.Y<minor>.Z<bug fix> schema. The process of tagging the application is wrapped in a Makefile command which also publishes the Docker image for that version to ECR.

Following the pattern set above of separating the application environment from the server environment, we deploy our code specifying what version of the application we are deploying to what server environment configuration. That would look something like:

```
$ deploy.sh v1.0.1 restribution-env
```

Inside the deploy script we create a .zip bundle of the Elastic Beanstalk server configuration and Dockerrun.aws.json file, which specifies the tagged Docker image on ECR to deploy. An Elastic Beanstalk command is executed which uploads the bundle and tags it with the version label. After that, the next command updates the server environment specified with the application bundle that was just uploaded and tagged. At this point, the deployment has been kicked off and the new version will start accepting traffic as soon as the server environment is green.

## What were the results?

Once we accomplished these goals, we're now able to reliably run the application locally, in a dev environment or in a production environment with a simple command. Furthermore, we are able to experiment with new versions by creating new feature branch eb envs.

Another example if it's success was the example of creating a container for running ALC and using EB to run that in 10 insances defined by a single eb env.
