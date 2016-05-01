# the name of the application
NAME=example
# aws ecr host e.g. <aws_account_id>.dkr.ecr.us-west-2.amazonaws.com
REGISTRY=${REGISTRY_HOST}
# the application's semantic version e.g. v1.0.1
VERSION=$(shell git describe --tags)
# env vars specific to your local app environment
ENV_FILE=./local.env


## Authenticate ecr with the docker cli for Pushing and Pulling images
ecrlogin:
	$(shell aws ecr get-login --region us-west-2)

## Ensure this system has a docker local.env file
dockerenv:
	@if [ ! -f $(ENV_FILE) ]; then \
	    echo "Missing docker env file. See README for instructions."; \
	    exit 1; \
	fi

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
publish: ecrlogin
	docker build -t $(NAME) --rm .
	docker tag $(NAME) $(REGISTRY)/$(NAME):$(VERSION)
	docker push $(REGISTRY)/$(NAME):$(VERSION)

## Create the server environment on Elastic Beanstalk
create:
	eb create example-env \
		--cname=chicagolang-example \
		--instance_type=t2.nano \
		--instance_profile=examplerole \
		--tags=Application=example,Service=eb \
		--envvars=GIN_MODE=release