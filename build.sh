#/bin/bash!

BRANCH=$(git rev-parse --abbrev-ref HEAD)
BRANCH=$(echo ${BRANCH/_/-})
BRANCH=$(echo ${BRANCH/\//-})
VERSION=$(cat package.json | jq -r .version)
IMAGE="chatwoot:${VERSION}-${BRANCH}"

aws ecr get-login-password --region us-east-1 |  docker login --username AWS --password-stdin 713562181720.dkr.ecr.us-east-1.amazonaws.com
docker build -t 713562181720.dkr.ecr.us-east-1.amazonaws.com/${IMAGE} -f docker/Dockerfile .
docker push  713562181720.dkr.ecr.us-east-1.amazonaws.com/${IMAGE}