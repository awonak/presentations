# deploy.sh
#! /bin/bash

APP_NAME=example
S3_BUCKET=awonak

function usage () {
    echo "deploy.sh\n  Usage: deploy.sh <VERSION> <EB Environment>"
    echo $USAGE >> /dev/stderr;
    if [ ! -z "$1" ]; then
        echo "  Error: ${1}";
    fi

    exit 1;
}

# validate that REGISTRY_HOST is set
# ex. <aws_account_id>.dkr.ecr.us-west-2.amazonaws.com
if [ -z "$REGISTRY_HOST" ]; then
    usage "env var for REGISTRY_HOST must be set.";
fi

# validate that awscli is installed
if ! which aws > /dev/null; then
    usage "awscli must be installed to run deploy.sh";
fi

# assert all required cli args were provided
[ "$#" -eq 2 ] || usage "too few arguments"

VERSION=$1
EB_ENV=$2


# Create new Elastic Beanstalk application version zip
SOURCE_BUNDLE="${EB_ENV}-${VERSION}.zip"

DOCKERRUN_FILE=Dockerrun.aws.json
IMAGE_NAME=$REGISTRY_HOST\\/$APP_NAME\:$VERSION
sed "s/<IMAGE_NAME>/$IMAGE_NAME/" < Dockerrun.aws.json.template > $DOCKERRUN_FILE

zip -r $SOURCE_BUNDLE .ebextensions/ $DOCKERRUN_FILE

aws s3 cp $SOURCE_BUNDLE s3://$S3_BUCKET/$APP_NAME/$SOURCE_BUNDLE
aws elasticbeanstalk create-application-version \
    --application-name $APP_NAME \
    --version-label $VERSION \
    --source-bundle S3Bucket=$S3_BUCKET,S3Key=$APP_NAME/$SOURCE_BUNDLE \
    --region $AWS_REGION

# Update Elastic Beanstalk environment to new version
aws elasticbeanstalk update-environment \
    --environment-name $EB_ENV \
    --version-label $VERSION \
    --region $AWS_REGION

# Cleanup temp files. Report success.
rm $DOCKERRUN_FILE $SOURCE_BUNDLE
echo "\nStarted deploy of version $VERSION to Environment $EB_ENV.";
exit 0;