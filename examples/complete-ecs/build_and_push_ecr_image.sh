#!/bin/bash

ACCOUNT_ID=$1
AWS_REGION=$2
REPO_URL=$3

GIT_COMMIT_HASH=$(git log -n 1 --pretty=format:'%H')

aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

docker build -t $REPO_URL:$GIT_COMMIT_HASH docker-test-image

docker tag $REPO_URL:$GIT_COMMIT_HASH $REPO_URL:latest

docker push $REPO_URL:$GIT_COMMIT_HASH
docker push $REPO_URL:latest