# deploy.sh
#! /bin/bash

function usage () {
    echo "deploy.sh\n  Usage: deploy.sh <VERSION> <EB Environment>"
    echo $USAGE >> /dev/stderr;
    if [ ! -z "$1" ]; then
        echo "  Error: ${1}";
    fi

    exit 1;
}

# validate that awscli is installed
if ! which aws > /dev/null; then
    usage "awscli must be installed to run deploy.sh";
fi

# assert all required cli args were provided
[ "$#" -eq 2 ] || usage "too few arguments"

VERSION=$1
EB_ENV=$2

# Update Elastic Beanstalk environment to new version
aws elasticbeanstalk update-environment \
    --environment-name $EB_ENV \
    --version-label $VERSION \
    --region $AWS_REGION

echo "\nStarted deploy of version $VERSION to Environment $EB_ENV.";
exit 0;