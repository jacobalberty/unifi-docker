#!/bin/sh

if [ "$TRAVIS_PULL_REQUEST" = "true" ]; then
  docker buildx build \
    --progress plain \
    --platform linux/arm/v7,linux/arm64/v8,linux/amd64 \
    -t unifi \
    .

# TODO: This doesn't work right now because it's looking for unifi:latest and the build tags it differently for some reason
#  docker run -d -p 8443:8443 -p 8080:8080 -e RUNAS_UID0=true --name unifi unifi
#  docker ps | grep -q unifi
#  docker logs unifi
#  sleep 10 && curl --connect-timeout 5 --max-time 10 --retry 5 --retry-delay 0 --retry-max-time 60 -kILs --fail http://127.0.0.1:8080 || exit 1

  exit $?
fi
TAG="${TRAVIS_TAG:-latest}"
echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin &> /dev/null
docker buildx build \
  --progress plain \
  --platform linux/arm/v7,linux/arm64/v8,linux/amd64 \
  -t $DOCKER_REPO:$TAG \
  --push \
  .
