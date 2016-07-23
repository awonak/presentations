# the name of the application
NAME=example
# aws ecr host e.g. <aws_account_id>.dkr.ecr.us-west-2.amazonaws.com
REGISTRY=${REGISTRY_HOST}
# the application's semantic version e.g. v1.0.1
VERSION=$(shell git describe --tags)
# env vars specific to your local app environment
ENV_FILE=./local.env
# the output filename for the aws eb Dockerrun file
DOCKERRUN_FILE="Dockerrun.aws.json"
# the output filename for the aws eb Dockerrun file
DOCKERRUN_TPL="Dockerrun.aws.json.template"
# specify the target aws region
AWS_REGION=us-east-1
# specify your aws s3 bucket to deploy application versions to
BUCKET=${EB_BUCKET}

## Run the docker build command to create the container and compile the
## application inside the container.
build:
	docker build -t $(NAME) --rm .

## Build and run the application using ENV_FILE for configuration.
run: dockerenv build
	docker run -it --publish=8080:8080 --env-file $(ENV_FILE) --name $(NAME)-dev --rm $(NAME)

## Run the test suite inside the docker container
test: build
	docker run -e "GIN_MODE=test" --name $(NAME)-test --rm $(NAME) go test -v -race ./...

## Build, Tag and Push the feature branch Docker image to the ECR
publish: ecrlogin build
	# Tag the docker image and pubish that image to AWS ECR
	docker tag $(NAME) $(REGISTRY)/$(NAME):$(VERSION)
	docker push $(REGISTRY)/$(NAME):$(VERSION)

	# Create an Application Version in Elastic Beanstalk
	$(eval SOURCE_BUNDLE := $(VERSION).zip )
	$(shell sed "s/<IMAGE_NAME>/$(REGISTRY)\/$(NAME):$(VERSION)/" < $(DOCKERRUN_TPL) > $(DOCKERRUN_FILE) )
	zip -r $(SOURCE_BUNDLE) .ebextensions/ $(DOCKERRUN_FILE)

	aws s3 cp $(SOURCE_BUNDLE) s3://$(BUCKET)/$(NAME)/$(SOURCE_BUNDLE)
	aws elasticbeanstalk create-application-version \
	    --application-name $(NAME) \
	    --version-label $(VERSION) \
	    --source-bundle S3Bucket=$(BUCKET),S3Key=$(NAME)/$(SOURCE_BUNDLE) \
	    --region us-east-1

	rm $(DOCKERRUN_FILE) $(SOURCE_BUNDLE)

## Authenticate ECR with the Docker cli for Pushing and Pulling Docker images to/from ECR
ecrlogin:
	$(shell aws ecr get-login --region $(AWS_REGION))

## Ensure this system has a docker local.env file
dockerenv:
	@if [ ! -f $(ENV_FILE) ]; then \
	    echo "Missing docker env file. See README for instructions."; \
	    exit 1; \
	fi
