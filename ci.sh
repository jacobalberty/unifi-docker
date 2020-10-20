#!/bin/sh

getTags() {
  BRANCH="${TRAVIS_BRANCH:-latest}"
  if [ $BRANCH = 'master' ]; then
    BRANCH=latest
  fi
  echo --tag $DOCKER_REPO:$BRANCH
  for tag in $DOCKER_TAGS; do
    echo --tag $DOCKER_REPO:$tag
  done
}

if [ "$TRAVIS_PULL_REQUEST" != "false" ]; then
  docker buildx build \
    --progress plain \
    --platform linux/arm/v7,linux/arm64/v8,linux/amd64 \
    .

  docker build -t unifi:latest .

  docker run -d -p 8443:8443 -p 8080:8080 -e PKGURL --name unifi unifi:latest
  docker ps | grep -q unifi
  docker logs unifi
  sleep 10 && curl --connect-timeout 5 --max-time 10 --retry 5 --retry-delay 0 --retry-max-time 60 -kILs --fail http://127.0.0.1:8080 || exit 1
  exit $?
fi
echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin &> /dev/null
docker buildx build \
  --progress plain \
  --platform linux/arm/v7,linux/arm64/v8,linux/amd64 \
  $(getTags) \
  --push \
  .
